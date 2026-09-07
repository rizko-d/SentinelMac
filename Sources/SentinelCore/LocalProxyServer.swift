import Foundation
import Network

public struct NetworkEvent: Identifiable, Sendable {
    public let id = UUID()
    public let timestamp: Date
    public let domain: String
    public let port: UInt16
    public let isBlocked: Bool
    public let processName: String
    public let processPID: pid_t

    public init(timestamp: Date = Date(), domain: String, port: UInt16, isBlocked: Bool, processName: String = "Unknown", processPID: pid_t = 0) {
        self.timestamp = timestamp
        self.domain = domain
        self.port = port
        self.isBlocked = isBlocked
        self.processName = processName
        self.processPID = processPID
    }
}

public final class LocalProxyServer: @unchecked Sendable {
    private let port: UInt16
    private let blocklist: BlocklistEngine
    private var listener: NWListener?
    private let queue = DispatchQueue(label: "com.sentinelmac.proxy", attributes: .concurrent)
    public var onEvent: (@Sendable (NetworkEvent) -> Void)?

    public init(port: UInt16 = 8080, blocklist: BlocklistEngine) {
        self.port = port
        self.blocklist = blocklist
    }

    public func start() throws {
        let params = NWParameters.tcp
        let nwPort = NWEndpoint.Port(rawValue: self.port)!
        let listener = try NWListener(using: params, on: nwPort)
        
        listener.newConnectionHandler = { [weak self] connection in
            self?.handleClient(connection: connection)
        }
        
        listener.stateUpdateHandler = { state in
            switch state {
            case .ready:
                print("[SentinelProxy] Listening on 127.0.0.1:\(self.port)")
            case .failed(let error):
                print("[SentinelProxy] Listener failed: \(error)")
            default:
                break
            }
        }
        
        self.listener = listener
        listener.start(queue: queue)
    }

    public func stop() {
        listener?.cancel()
        listener = nil
        print("[SentinelProxy] Stopped listener.")
    }

    private func handleClient(connection: NWConnection) {
        connection.start(queue: queue)
        
        // Read initial HTTP request (CONNECT or plain HTTP)
        connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] content, _, isComplete, error in
            guard let self = self, let data = content, error == nil else {
                connection.cancel()
                return
            }

            guard let requestLine = String(data: data, encoding: .utf8)?.components(separatedBy: "\r\n").first else {
                connection.cancel()
                return
            }

            // HTTP CONNECT method (HTTPS tunneling)
            if requestLine.starts(with: "CONNECT ") {
                let parts = requestLine.split(separator: " ")
                if parts.count >= 2 {
                    let hostPort = parts[1].split(separator: ":")
                    let targetHost = String(hostPort[0])
                    let targetPort = hostPort.count > 1 ? (UInt16(hostPort[1]) ?? 443) : 443
                    
                    self.evaluateAndRelay(
                        clientConn: connection,
                        targetHost: targetHost,
                        targetPort: targetPort,
                        isCONNECT: true
                    )
                    return
                }
            }

            // Plain HTTP or raw packet
            connection.cancel()
        }
    }

    private func evaluateAndRelay(clientConn: NWConnection, targetHost: String, targetPort: UInt16, isCONNECT: Bool) {
        let blocked = blocklist.isBlocked(domain: targetHost)
        let event = NetworkEvent(domain: targetHost, port: targetPort, isBlocked: blocked)
        onEvent?(event)

        if blocked {
            print("[SentinelProxy] BLOCKED tracking request to: \(targetHost):\(targetPort)")
            let response = "HTTP/1.1 403 Forbidden\r\nContent-Type: text/plain\r\nConnection: close\r\n\r\n[SentinelMac] Tracker domain blocked by policy.\r\n"
            clientConn.send(content: response.data(using: .utf8), completion: .contentProcessed({ _ in
                clientConn.cancel()
            }))
            return
        }

        if isCONNECT {
            // Establish target connection
            let endpoint = NWEndpoint.hostPort(host: .init(targetHost), port: .init(rawValue: targetPort)!)
            let upstreamConn = NWConnection(to: endpoint, using: .tcp)
            
            upstreamConn.stateUpdateHandler = { state in
                if case .ready = state {
                    // Send HTTP 200 Connection Established to client
                    let established = "HTTP/1.1 200 Connection Established\r\n\r\n".data(using: .utf8)!
                    clientConn.send(content: established, completion: .contentProcessed({ _ in
                        // Pipe traffic bidirectionally without decryption
                        self.pipe(from: clientConn, to: upstreamConn)
                        self.pipe(from: upstreamConn, to: clientConn)
                    }))
                } else if case .failed = state {
                    clientConn.cancel()
                }
            }
            upstreamConn.start(queue: queue)
        }
    }

    private func pipe(from src: NWConnection, to dst: NWConnection) {
        src.receive(minimumIncompleteLength: 1, maximumLength: 16384) { [weak self] data, _, isComplete, error in
            guard let self = self else { return }
            if let data = data, !data.isEmpty {
                dst.send(content: data, completion: .contentProcessed({ sendErr in
                    if sendErr == nil {
                        self.pipe(from: src, to: dst)
                    } else {
                        src.cancel()
                        dst.cancel()
                    }
                }))
            } else if isComplete || error != nil {
                src.cancel()
                dst.cancel()
            }
        }
    }
}
