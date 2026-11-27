import Foundation
import CoreBluetooth

enum BridgeProtocol {

    // MARK: - Identificação do serviço Ponte

    static let serviceUUID = CBUUID(
        string: "7A1B0001-5A3D-4E2F-9C8B-1D6E7F8A9B00"
    )

    // MARK: - Características BLE

    // Dados enviados pelo relógio ao iPhone.
    static let dataUUID = CBUUID(
        string: "7A1B0002-5A3D-4E2F-9C8B-1D6E7F8A9B00"
    )

    // Confirmações enviadas pelo iPhone ao relógio.
    static let controlUUID = CBUUID(
        string: "7A1B0003-5A3D-4E2F-9C8B-1D6E7F8A9B00"
    )

    // MARK: - Identificação do protocolo

    static let protocolName = "Ponte"
    static let protocolVersion = 1

        // MARK: - Formato dos pacotes

    static let packetMagic: [UInt8] = [0x50, 0x54]
    static let packetVersion: UInt8 = 1

    // 2 bytes de identificação + 1 de versão
    // + 2 de ID + 2 de índice + 2 de quantidade.
    static let packetHeaderLength = 9

    static let maximumChunkCount: UInt16 = 1024
    static let maximumMessageSize = 256 * 1024
}
