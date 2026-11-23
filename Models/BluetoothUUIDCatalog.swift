
import Foundation

enum BluetoothUUIDCatalog {

    // MARK: - Normalização de UUID

    private static func normalize(_ uuid: String) -> String {
        let value = uuid
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "{", with: "")
            .replacingOccurrences(of: "}", with: "")

        // Base UUID oficial do Bluetooth.
        let bluetoothBase = "00001000800000805F9B34FB"

        // Converte UUID Bluetooth de 16 bits expandido
        // para sua representação curta.
        if value.count == 32,
           value.hasSuffix(bluetoothBase),
           value.hasPrefix("0000") {

            return String(value.dropFirst(4).prefix(4))
        }

        return value
    }

    // MARK: - Serviços GATT conhecidos

    private static let services: [String: String] = [

        // Serviços básicos
        "1800": "Generic Access - Acesso genérico",
        "1801": "Generic Attribute - Atributos genéricos",
        "1802": "Immediate Alert - Alerta imediato",
        "1803": "Link Loss - Perda de conexão",
        "1804": "Tx Power - Potência de transmissão",
        "1805": "Current Time - Horário atual",
        "1806": "Reference Time Update - Atualização de horário",
        "1807": "Next DST Change - Próxima mudança de horário",
        "180A": "Device Information - Informações do dispositivo",
        "180B": "Network Availability - Disponibilidade de rede",
        "180D": "Heart Rate - Frequência cardíaca",
        "180E": "Phone Alert Status - Status de alertas do telefone",
        "180F": "Battery Service - Serviço de bateria",

        // Saúde
        "1808": "Glucose - Glicose",
        "1809": "Health Thermometer - Termômetro de saúde",
        "1810": "Blood Pressure - Pressão arterial",
        "181B": "Body Composition - Composição corporal",
        "181C": "User Data - Dados do usuário",
        "181D": "Weight Scale - Balança",
        "181F": "Continuous Glucose Monitoring - Monitoramento contínuo de glicose",
        "1822": "Pulse Oximeter - Oxímetro de pulso",

        // Alertas e interação
        "1811": "Alert Notification - Notificações de alerta",
        "1812": "Human Interface Device - Dispositivo de interface humana",
        "1813": "Scan Parameters - Parâmetros de busca",
        "1815": "Automation IO - Automação de entrada e saída",

        // Atividades físicas
        "1814": "Running Speed and Cadence - Corrida",
        "1816": "Cycling Speed and Cadence - Ciclismo",
        "1818": "Cycling Power - Potência de ciclismo",
        "1819": "Location and Navigation - Localização e navegação",
        "1826": "Fitness Machine - Equipamento de exercício",

        // Sensores e ambiente
        "181A": "Environmental Sensing - Sensores ambientais",

        // Outros serviços
        "181E": "Bond Management - Gerenciamento de pareamento",
        "1820": "Internet Protocol Support - Suporte a IP",
        "1821": "Indoor Positioning - Posicionamento interno",
        "1823": "HTTP Proxy - Proxy HTTP",
        "1824": "Transport Discovery - Descoberta de transporte",
        "1825": "Object Transfer - Transferência de objetos",
        "1827": "Mesh Provisioning - Provisionamento Mesh",
        "1828": "Mesh Proxy - Proxy Mesh",
        "1829": "Reconnection Configuration - Configuração de reconexão"
    ]

    // MARK: - Características GATT conhecidas

    private static let characteristics: [String: String] = [

        // Identificação do dispositivo
        "2A00": "Device Name - Nome do dispositivo",
        "2A01": "Appearance - Aparência do dispositivo",
        "2A02": "Peripheral Privacy Flag - Privacidade do dispositivo",
        "2A03": "Reconnection Address - Endereço de reconexão",
        "2A04": "Peripheral Preferred Connection Parameters - Parâmetros de conexão",
        "2A05": "Service Changed - Serviço alterado",

        // Alertas e transmissão
        "2A06": "Alert Level - Nível de alerta",
        "2A07": "Tx Power Level - Potência de transmissão",

        // Data e horário
        "2A08": "Date Time - Data e hora",
        "2A09": "Day Date Time - Dia, data e hora",
        "2A0A": "Exact Time 256 - Horário exato",
        "2A0C": "Time Source - Fonte de horário",
        "2A0D": "Reference Time Information - Informações de horário",
        "2A0E": "Time Zone - Fuso horário",
        "2A0F": "Local Time Information - Horário local",
        "2A11": "Time with DST - Horário com horário de verão",
        "2A14": "Time Update Control Point - Controle de atualização de horário",
        "2A16": "Time Update State - Estado da atualização de horário",

        // Bateria
        "2A19": "Battery Level - Nível da bateria",
        "2A1A": "Battery Power State - Estado de energia da bateria",
        "2A1B": "Battery Level State - Estado do nível da bateria",

        // Temperatura
        "2A1C": "Temperature Measurement - Medição de temperatura",
        "2A1D": "Temperature Type - Tipo de temperatura",
        "2A1E": "Intermediate Temperature - Temperatura intermediária",

        // Informações do dispositivo
        "2A23": "System ID - Identificação do sistema",
        "2A24": "Model Number String - Número do modelo",
        "2A25": "Serial Number String - Número de série",
        "2A26": "Firmware Revision String - Versão do firmware",
        "2A27": "Hardware Revision String - Versão do hardware",
        "2A28": "Software Revision String - Versão do software",
        "2A29": "Manufacturer Name String - Fabricante",
        "2A2A": "IEEE 11073-20601 Regulatory Certification Data List",
        "2A2B": "PnP ID - Identificação Plug and Play",

        // Pressão arterial
        "2A35": "Blood Pressure Measurement - Medição de pressão arterial",
        "2A36": "Intermediate Cuff Pressure - Pressão intermediária",
        
        // Frequência cardíaca
        "2A37": "Heart Rate Measurement - Medição cardíaca",
        "2A38": "Body Sensor Location - Localização do sensor corporal",
        "2A39": "Heart Rate Control Point - Controle cardíaco",

        // Glicose
        "2A18": "Glucose Measurement - Medição de glicose",
        "2A34": "Glucose Measurement Context - Contexto da medição de glicose",
        "2A51": "Glucose Feature - Recursos de glicose",

        // Sensores ambientais
        "2A6D": "Pressure - Pressão",
        "2A6E": "Temperature - Temperatura",
        "2A6F": "Humidity - Umidade",

        // Oxigenação do sangue
        "2A5F": "PLX Spot-Check Measurement - Medição pontual de oxigenação",
        "2A60": "PLX Continuous Measurement - Medição contínua de oxigenação",

        // Composição corporal
        "2A9B": "Body Composition Feature - Recursos de composição corporal",
        "2A9C": "Body Composition Measurement - Medição de composição corporal",

        // Peso corporal
        "2A9D": "Weight Measurement - Medição de peso",
        "2A9E": "Weight Scale Feature - Recursos da balança",
        "2A9F": "User Data - Dados do usuário",
        "2AA0": "Height - Altura"
    ]


    // MARK: - Classificação de serviços GATT

    static func serviceCategory(for uuid: String) -> String {

        let normalized = normalize(uuid)

        switch normalized {

        case "1800", "1801":
            return "Serviços básicos GATT"

        case "180A":
            return "Informações do dispositivo"

        case "1808", "1809", "1810", "181B",
             "181C", "181D", "181F", "1822":
            return "Saúde e sensores corporais"

        case "180D", "1814", "1816", "1818",
             "1819", "1826":
            return "Atividade física"

        case "1802", "1803", "180E", "1811", "1812":
            return "Alertas e interação"

        case "181A":
            return "Sensoriamento ambiental"

        case "1804", "1805", "1806", "1807",
             "180B", "1813", "1815", "181E",
             "1820", "1821", "1823", "1824",
             "1825", "1827", "1828", "1829":
            return "Conectividade e recursos do dispositivo"

        default:

            if services[normalized] != nil {
                return "Outro serviço padrão"
            }

            return "Serviço não catalogado"
        }
    }



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

    // MARK: - Classificação de UUID

    static func uuidType(for uuid: String) -> String {
        let normalized = normalize(uuid)

        switch normalized.count {
        case 4:
            return "UUID Bluetooth de 16 bits"

        case 8:
            return "UUID de 32 bits"

        case 32:
            return "UUID de 128 bits"

        default:
            return "Formato de UUID não reconhecido"
        }
    }

    // MARK: - UUIDs desconhecidos

    private static func unknownUUIDDescription(_ uuid: String) -> String {

        switch uuid.count {
        case 4:
            return "UUID Bluetooth de 16 bits não catalogado"

        case 8:
            return "UUID de 32 bits não catalogado"

        case 32:
            return "UUID de 128 bits não catalogado - pode ser personalizado"

        default:
            return "UUID desconhecido ou em formato inválido"
        }
    }
}
