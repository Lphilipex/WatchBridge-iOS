
import Foundation

enum BluetoothUUIDCatalog {

    // MARK: - Normalização de UUID

    private static func normalize(_ uuid: String) -> String {
        let value = uuid
            .uppercased()
            .replacingOccurrences(of: "-", with: "")

        // UUID Bluetooth padrão de 16 bits expandido para 128 bits.
        let bluetoothBase = "00001000800000805F9B34FB"

        if value.count == 32,
           value.hasSuffix(bluetoothBase),
           value.hasPrefix("0000") {

            return String(value.dropFirst(4).prefix(4))
        }

        return value
    }

    // MARK: - Serviços GATT conhecidos

    private static let services: [String: String] = [
        "1800": "Generic Access - Acesso genérico",
        "1801": "Generic Attribute - Atributos genéricos",
        "180A": "Device Information - Informações do dispositivo",
        "180F": "Battery Service - Serviço de bateria",
        "1805": "Current Time - Horário atual",
        "180D": "Heart Rate - Frequência cardíaca",
        "1812": "Human Interface Device - Dispositivo de interface humana",
        "1814": "Running Speed and Cadence - Corrida",
        "1816": "Cycling Speed and Cadence - Ciclismo",
        "1818": "Cycling Power - Potência de ciclismo",
        "181A": "Environmental Sensing - Sensores ambientais",
        "181B": "Body Composition - Composição corporal",
        "181C": "User Data - Dados do usuário",
        "1826": "Fitness Machine - Equipamento de exercício"
    ]

    // MARK: - Características GATT conhecidas

    private static let characteristics: [String: String] = [
        "2A00": "Device Name - Nome do dispositivo",
        "2A01": "Appearance - Aparência do dispositivo",
        "2A04": "Peripheral Preferred Connection Parameters",
        "2A05": "Service Changed - Serviço alterado",

        "2A19": "Battery Level - Nível da bateria",

        "2A24": "Model Number String - Número do modelo",
        "2A25": "Serial Number String - Número de série",
        "2A26": "Firmware Revision String - Versão do firmware",
        "2A27": "Hardware Revision String - Versão do hardware",
        "2A28": "Software Revision String - Versão do software",
        "2A29": "Manufacturer Name String - Fabricante",

        "2A2A": "IEEE 11073-20601 Regulatory Certification Data List",
        "2A23": "System ID - Identificação do sistema",

        "2A37": "Heart Rate Measurement - Medição cardíaca",
        "2A38": "Body Sensor Location - Localização do sensor",
        "2A39": "Heart Rate Control Point - Controle cardíaco",

        "2A6E": "Temperature - Temperatura",
        "2A6F": "Humidity - Umidade",
        "2A6D": "Pressure - Pressão"
    ]

    // MARK: - Identificação de serviços

    static func serviceName(for uuid: String) -> String {
        let normalized = normalize(uuid)

        if let name = services[normalized] {
            return name
        }

        return unknownUUIDDescription(normalized)
    }

    // MARK: - Identificação de características

    static func characteristicName(for uuid: String) -> String {
        let normalized = normalize(uuid)

        if let name = characteristics[normalized] {
            return name
        }

        return unknownUUIDDescription(normalized)
    }

    // MARK: - UUIDs desconhecidos

    private static func unknownUUIDDescription(_ uuid: String) -> String {
        if uuid.count == 32 {
            return "UUID não catalogado - possivelmente específico do fabricante"
        }

        return "UUID padrão não catalogado"
    }
}
