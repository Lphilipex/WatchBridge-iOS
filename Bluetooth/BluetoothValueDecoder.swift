
import Foundation

// MARK: - Interpretador de valores BLE

enum BluetoothValueDecoder {

    static func decode(
        characteristicUUID: String,
        data: Data
    ) -> String {

        let uuid = characteristicUUID
            .uppercased()
            .replacingOccurrences(of: "-", with: "")

        let bytes = [UInt8](data)

        guard !bytes.isEmpty else {
            return "Nenhum dado recebido"
        }

        switch String(uuid.suffix(4)) {

        // MARK: - Nível da bateria

        case "2A19":

            let batteryLevel = Int(bytes[0])

            if batteryLevel <= 100 {
                return "\(batteryLevel)%"
            }

            return "Nível de bateria inválido: \(batteryLevel)"

        // MARK: - Frequência cardíaca

        case "2A37":

            guard bytes.count >= 2 else {
                return "Dados insuficientes para frequência cardíaca"
            }

            let flags = bytes[0]

            let usesUInt16 = (flags & 0x01) != 0

            let heartRate: Int

            if usesUInt16 {

                guard bytes.count >= 3 else {
                    return "Dados incompletos para frequência cardíaca"
                }

                heartRate =
                    Int(bytes[1]) |
                    (Int(bytes[2]) << 8)

            } else {

                heartRate = Int(bytes[1])
            }

            return "\(heartRate) bpm"

        // MARK: - Característica desconhecida

        default:

            let hexadecimal = bytes.map {
                String(format: "%02X", $0)
            }
            .joined(separator: " ")

            return "Dados brutos: \(hexadecimal)"
        }
    }
}

