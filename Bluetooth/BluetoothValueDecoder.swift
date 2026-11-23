
import Foundation

// MARK: - Interpretador de valores BLE

enum BluetoothValueDecoder {

    static func decode(
        characteristicUUID: String,
        data: Data
    ) -> String {

        let uuid = normalizeUUID(characteristicUUID)
        let bytes = [UInt8](data)

        guard !bytes.isEmpty else {
            return "Nenhum dado recebido"
        }

        switch uuid {

        // MARK: - Informações do dispositivo

        case "2A29":
            return decodeText(data, label: "Fabricante")

        case "2A24":
            return decodeText(data, label: "Modelo")

        case "2A25":
            return decodeText(data, label: "Número de série")

        case "2A26":
            return decodeText(data, label: "Firmware")

        case "2A27":
            return decodeText(data, label: "Hardware")

        case "2A28":
            return decodeText(data, label: "Software")

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

    // MARK: - Normalização de UUID

    private static func normalizeUUID(_ uuid: String) -> String {

        let normalized = uuid
            .uppercased()
            .replacingOccurrences(of: "-", with: "")

        // UUID Bluetooth de 16 bits.
        if normalized.count == 4 {
            return normalized
        }

        // UUID Bluetooth padrão expandido para 128 bits.
        let bluetoothBase = "00001000800000805F9B34FB"

        if normalized.count == 32,
           normalized.hasPrefix("0000"),
           normalized.hasSuffix(bluetoothBase) {

            return String(normalized.prefix(8).suffix(4))
        }

        return normalized
    }

    // MARK: - Conversão de texto

    private static func decodeText(
        _ data: Data,
        label: String
    ) -> String {

        guard let text = String(data: data, encoding: .utf8) else {
            return "\(label): texto não reconhecido"
        }

        let value = text
            .trimmingCharacters(in: .controlCharacters)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !value.isEmpty else {
            return "\(label): informação vazia"
        }

        return "\(label): \(value)"
    }
}
