
import SwiftUI

struct DashboardView: View {

    @StateObject private var bluetooth = BluetoothManager()

    @State private var writeValues: [String: String] = [:]

    var body: some View {
        NavigationStack {
            VStack(spacing: 15) {

                // MARK: - Cabeçalho

                Image(systemName: "applewatch")
                    .font(.system(size: 55))
                    .foregroundStyle(.blue)

                Text("WatchBridge")
                    .font(.largeTitle.bold())

                Text("Galaxy Watch 4 Classic")
                    .font(.headline)

                Text(bluetooth.status)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                // MARK: - Controles Bluetooth

                if bluetooth.isConnected {

                    Label(
                        "Conectado: \(bluetooth.connectedDeviceName ?? "Dispositivo")",
                        systemImage: "checkmark.circle.fill"
                    )
                    .foregroundStyle(.green)

                    Button("Desconectar") {
                        bluetooth.disconnect()
                    }
                    .buttonStyle(.bordered)

                } else if bluetooth.isConnecting {

                    ProgressView("Conectando...")

                } else if bluetooth.isScanning {

                    Button("Parar busca") {
                        bluetooth.stopScan()
                    }
                    .buttonStyle(.bordered)

                } else {

                    Button("Procurar dispositivos") {
                        bluetooth.startScan()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!bluetooth.isBluetoothReady)
                }

                Divider()

                // MARK: - Lista principal

                List {

                    // MARK: - Dispositivos encontrados

                    Section("Dispositivos encontrados") {

                        if bluetooth.devices.isEmpty {

                            Text("Nenhum dispositivo encontrado")
                                .foregroundStyle(.secondary)

                        } else {

                            ForEach(bluetooth.devices) { device in

                                VStack(
                                    alignment: .leading,
                                    spacing: 10
                                ) {

                                    // MARK: - Resumo do dispositivo

                                    HStack {

                                        VStack(
                                            alignment: .leading,
                                            spacing: 4
                                        ) {

                                            Text(device.name)
                                                .font(.headline)
                                                .foregroundStyle(.primary)

                                            Text(device.id.uuidString)
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                                .textSelection(.enabled)
                                        }

                                        Spacer()

                                        if device.isLikelyGalaxyWatch {

                                            Label(
                                                "Samsung?",
                                                systemImage: "applewatch"
                                            )
                                            .font(.caption)
                                            .foregroundStyle(.green)
                                        }
                                    }

                                    // MARK: - Informações rápidas

                                    VStack(
                                        alignment: .leading,
                                        spacing: 6
                                    ) {

                                        HStack(spacing: 16) {

                                            Label(
                                                "\(device.rssi) dBm",
                                                systemImage: "wifi"
                                            )

                                            if let txPower = device.txPower {

                                                Label(
                                                    "\(txPower) dBm",
                                                    systemImage: "antenna.radiowaves.left.and.right"
                                                )
                                            }
                                        }

                                        if let isConnectable = device.isConnectable {

                                            Label(
                                                isConnectable
                                                    ? "Conectável"
                                                    : "Não conectável",
                                                systemImage: isConnectable
                                                    ? "checkmark.circle"
                                                    : "xmark.circle"
                                            )
                                        }
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                    // MARK: - Detalhes técnicos

                                    DisclosureGroup {

                                        VStack(
                                            alignment: .leading,
                                            spacing: 12
                                        ) {

                                            // Nome anunciado

                                            VStack(
                                                alignment: .leading,
                                                spacing: 3
                                            ) {

                                                Text("Nome anunciado")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)

                                                Text(
                                                    device.advertisedName
                                                        ?? "Não informado"
                                                )
                                                .font(.caption)
                                                .textSelection(.enabled)
                                            }

                                            Divider()

                                            // Serviços anunciados

                                            VStack(
                                                alignment: .leading,
                                                spacing: 3
                                            ) {

                                                Text("Serviços anunciados")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)

                                                Text(
                                                    device.advertisedServices.isEmpty
                                                        ? "Nenhum serviço anunciado"
                                                        : device.advertisedServices.joined(separator: ", ")
                                                )
                                                .font(.caption2)
                                                .textSelection(.enabled)
                                            }

                                            Divider()

                                            // Dados do fabricante

                                            VStack(
                                                alignment: .leading,
                                                spacing: 3
                                            ) {

                                                Text("Dados do fabricante")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)

                                                Text(
                                                    device.manufacturerData
                                                        ?? "Não informado"
                                                )
                                                .font(.caption2)
                                                .textSelection(.enabled)
                                            }

                                            Divider()

                                            // Serviços solicitados

                                            VStack(
                                                alignment: .leading,
                                                spacing: 3
                                            ) {

                                                Text("Serviços solicitados")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)

                                                Text(
                                                    device.solicitedServices.isEmpty
                                                        ? "Nenhum serviço solicitado"
                                                        : device.solicitedServices.joined(separator: ", ")
                                                )
                                                .font(.caption2)
                                                .textSelection(.enabled)
                                            }

                                            Divider()

                                            // Dados dos serviços

                                            VStack(
                                                alignment: .leading,
                                                spacing: 3
                                            ) {

                                                Text("Dados dos serviços")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)

                                                Text(
                                                    device.serviceData.isEmpty
                                                        ? "Nenhum dado de serviço"
                                                        : device.serviceData.map {
                                                            "\($0.key): \($0.value)"
                                                        }
                                                        .sorted()
                                                        .joined(separator: "\n")
                                                )
                                                .font(.caption2)
                                                .textSelection(.enabled)
                                            }

                                            Divider()

                                            // Serviços em overflow

                                            VStack(
                                                alignment: .leading,
                                                spacing: 3
                                            ) {

                                                Text("Serviços em overflow")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)

                                                Text(
                                                    device.overflowServices.isEmpty
                                                        ? "Nenhum serviço em overflow"
                                                        : device.overflowServices.joined(separator: ", ")
                                                )
                                                .font(.caption2)
                                                .textSelection(.enabled)
                                            }
                                        }
                                        .padding(.top, 8)

                                    } label: {

                                        Label(
                                            "Detalhes técnicos BLE",
                                            systemImage: "antenna.radiowaves.left.and.right"
                                        )
                                        .font(.subheadline)
                                    }

                                    // MARK: - Conectar

                                    Button {

                                        bluetooth.connect(to: device)

                                    } label: {

                                        Label(
                                            "Conectar ao dispositivo",
                                            systemImage: "link"
                                        )
                                        .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .disabled(
                                        bluetooth.isConnected ||
                                        bluetooth.isConnecting
                                    )
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }

                    // MARK: - Seções disponíveis quando conectado

                    if bluetooth.isConnected {

                        // MARK: - Identificação do dispositivo

                        Section("Identificação do dispositivo") {

                            LabeledContent("Fabricante") {
                                Text(
                                    deviceInformationValue(
                                        for: "2A29",
                                        label: "Fabricante"
                                    )
                                )
                                .textSelection(.enabled)
                            }

                            LabeledContent("Modelo") {
                                Text(
                                    deviceInformationValue(
                                        for: "2A24",
                                        label: "Modelo"
                                    )
                                )
                                .textSelection(.enabled)
                            }

                            LabeledContent("Número de série") {
                                Text(
                                    deviceInformationValue(
                                        for: "2A25",
                                        label: "Número de série"
                                    )
                                )
                                .textSelection(.enabled)
                            }

                            LabeledContent("Firmware") {
                                Text(
                                    deviceInformationValue(
                                        for: "2A26",
                                        label: "Firmware"
                                    )
                                )
                                .textSelection(.enabled)
                            }

                            LabeledContent("Hardware") {
                                Text(
                                    deviceInformationValue(
                                        for: "2A27",
                                        label: "Hardware"
                                    )
                                )
                                .textSelection(.enabled)
                            }

                            LabeledContent("Software") {
                                Text(
                                    deviceInformationValue(
                                        for: "2A28",
                                        label: "Software"
                                    )
                                )
                                .textSelection(.enabled)
                            }

                            LabeledContent("Bateria") {
                                Text(
                                    deviceInformationValue(
                                        for: "2A19",
                                        label: "Bateria"
                                    )
                                )
                                .textSelection(.enabled)
                            }
                        }

                        // MARK: - Serviços GATT

                        Section {

                            if bluetooth.discoveredServices.isEmpty {

                                Text("Aguardando serviços...")
                                    .foregroundStyle(.secondary)

                            } else {

                                ForEach(
                                    bluetooth.discoveredServices,
                                    id: \.self
                                ) { service in

                                    VStack(
                                        alignment: .leading,
                                        spacing: 6
                                    ) {

                                        Label(
                                            BluetoothUUIDCatalog.serviceName(
                                                for: service
                                            ),
                                            systemImage: "server.rack"
                                        )
                                        .font(.headline)

                                        Text("UUID: \(service)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .textSelection(.enabled)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }

                        } header: {

                            HStack {

                                Text("Serviços GATT")

                                Spacer()

                                Text(
                                    "\(bluetooth.discoveredServices.count)"
                                )
                                .foregroundStyle(.secondary)
                            }
                        }

                        // MARK: - Características Bluetooth

                        Section {

                            if bluetooth.discoveredCharacteristics.isEmpty {

                                Text("Aguardando características...")
                                    .foregroundStyle(.secondary)

                            } else {

                                ForEach(
                                    bluetooth.discoveredCharacteristics
                                ) { characteristic in

                                    VStack(
                                        alignment: .leading,
                                        spacing: 10
                                    ) {

                                        // Identificação

                                        VStack(
                                            alignment: .leading,
                                            spacing: 4
                                        ) {

                                            Text(
                                                characteristic.characteristicName
                                            )
                                            .font(.headline)
                                            .foregroundStyle(.blue)

                                            Text(
                                                "UUID: \(characteristic.uuid)"
                                            )
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                            .textSelection(.enabled)

                                            Text(
                                                "Tipo: \(characteristic.uuidType)"
                                            )
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        }

                                        Divider()

                                        // Serviço relacionado

                                        VStack(
                                            alignment: .leading,
                                            spacing: 4
                                        ) {

                                            Text("Serviço relacionado")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)

                                            Text(characteristic.serviceName)
                                                .font(.subheadline)

                                            Text(characteristic.serviceUUID)
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                                .textSelection(.enabled)
                                        }

                                        // Propriedades Bluetooth

                                        VStack(
                                            alignment: .leading,
                                            spacing: 5
                                        ) {

                                            Text("Propriedades Bluetooth")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)

                                            Text(
                                                characteristic.propertiesDescription
                                            )
                                            .font(.caption)
                                            .textSelection(.enabled)

                                            Text(
                                                characteristic.permissionsSummary
                                            )
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        }

                                        // Capacidades

                                        VStack(
                                            alignment: .leading,
                                            spacing: 5
                                        ) {

                                            Text("Capacidades")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)

                                            HStack(spacing: 6) {

                                                capabilityLabel(
                                                    "Leitura",
                                                    enabled: characteristic.isReadable
                                                )

                                                capabilityLabel(
                                                    "Escrita",
                                                    enabled: characteristic.isWritable ||
                                                        characteristic.supportsWriteWithoutResponse
                                                )
                                            }

                                            HStack(spacing: 6) {

                                                capabilityLabel(
                                                    "Notify",
                                                    enabled: characteristic.supportsNotify
                                                )

                                                capabilityLabel(
                                                    "Indicate",
                                                    enabled: characteristic.supportsIndications
                                                )
                                            }
                                        }

                                        Divider()

                                        // Valor recebido

                                        VStack(
                                            alignment: .leading,
                                            spacing: 5
                                        ) {

                                            Label(
                                                "Valor da característica",
                                                systemImage: "waveform.path"
                                            )
                                            .font(.caption)
                                            .foregroundStyle(.secondary)

                                            Text(characteristic.value)
                                                .font(.subheadline)
                                                .textSelection(.enabled)
                                        }

                                        // MARK: - Ações

                                        VStack(
                                            alignment: .leading,
                                            spacing: 8
                                        ) {

                                            // Leitura

                                            if characteristic.isReadable {

                                                Button {
                                                    bluetooth.readCharacteristic(
                                                        characteristic
                                                    )
                                                } label: {

                                                    Label(
                                                        "Ler característica",
                                                        systemImage: "arrow.clockwise"
                                                    )
                                                }
                                                .buttonStyle(.bordered)

                                            } else {

                                                Label(
                                                    "Leitura não disponível",
                                                    systemImage: "xmark.circle"
                                                )
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            }

                                            // Notificações

                                            if characteristic.supportsNotifications {

                                                Button {

                                                    bluetooth.toggleNotifications(
                                                        characteristic
                                                    )

                                                } label: {

                                                    Label(
                                                        characteristic.notificationsEnabled
                                                            ? "Desativar atualizações"
                                                            : "Ativar atualizações",
                                                        systemImage: characteristic.notificationsEnabled
                                                            ? "bell.slash"
                                                            : "bell.badge"
                                                    )
                                                }
                                                .buttonStyle(.borderedProminent)
                                            }

                                            // Escrita hexadecimal

                                            if characteristic.isWritable ||
                                                characteristic.supportsWriteWithoutResponse {

                                                VStack(
                                                    alignment: .leading,
                                                    spacing: 8
                                                ) {

                                                    Text("Enviar dados (HEX)")
                                                        .font(.subheadline.bold())

                                                    TextField(
                                                        "Ex.: 01 02 FF",
                                                        text: Binding(
                                                            get: {
                                                                writeValues[characteristic.id] ?? ""
                                                            },
                                                            set: {
                                                                writeValues[characteristic.id] = $0
                                                            }
                                                        )
                                                    )
                                                    .textInputAutocapitalization(.characters)
                                                    .autocorrectionDisabled()
                                                    .textFieldStyle(.roundedBorder)

                                                    Button {

                                                        bluetooth.writeCharacteristic(
                                                            characteristic,
                                                            hexadecimalValue: writeValues[characteristic.id] ?? ""
                                                        )

                                                    } label: {

                                                        Label(
                                                            "Enviar dados",
                                                            systemImage: "paperplane"
                                                        )
                                                    }
                                                    .buttonStyle(.borderedProminent)
                                                }
                                                .padding(.vertical, 5)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                            }

                        } header: {

                            HStack {

                                Text("Características Bluetooth")

                                Spacer()

                                Text(
                                    "\(bluetooth.discoveredCharacteristics.count)"
                                )
                                .foregroundStyle(.secondary)
                            }
                        }

                        // MARK: - Eventos de notificações BLE

                        Section("Eventos de notificações BLE") {

                            if bluetooth.notificationEvents.isEmpty {

                                Text("Nenhuma atualização recebida")
                                    .foregroundStyle(.secondary)

                            } else {

                                ForEach(
                                    Array(
                                        bluetooth.notificationEvents.enumerated()
                                    ),
                                    id: \.offset
                                ) { _, event in

                                    Text(event)
                                        .font(.caption)
                                        .textSelection(.enabled)
                                }
                            }
                        }
                    }

                    // MARK: - Painel de diagnóstico

                    Section {

                        LabeledContent(
                            "Bluetooth",
                            value: bluetooth.isBluetoothReady
                                ? "Disponível"
                                : "Indisponível"
                        )

                        LabeledContent(
                            "Estado da conexão",
                            value: bluetooth.isConnected
                                ? "Conectado"
                                : "Desconectado"
                        )

                        LabeledContent(
                            "Dispositivos encontrados",
                            value: "\(bluetooth.devices.count)"
                        )

                        LabeledContent(
                            "Serviços GATT",
                            value: "\(bluetooth.discoveredServices.count)"
                        )

                        LabeledContent(
                            "Características",
                            value: "\(bluetooth.discoveredCharacteristics.count)"
                        )

                        LabeledContent(
                            "Eventos de notificações",
                            value: "\(bluetooth.notificationEvents.count)"
                        )

                        LabeledContent(
                            "Eventos de diagnóstico",
                            value: "\(bluetooth.diagnosticEvents.count)"
                        )

                        ShareLink(
                            item: bluetooth.diagnosticReport
                        ) {

                            Label(
                                "Exportar relatório de diagnóstico",
                                systemImage: "square.and.arrow.up"
                            )
                        }

                    } header: {

                        Text("Painel de diagnóstico")
                    }

                    // MARK: - Histórico de diagnóstico

                    Section("Histórico de diagnóstico") {

                        if bluetooth.diagnosticEvents.isEmpty {

                            Text("Nenhum evento registrado.")
                                .foregroundStyle(.secondary)

                        } else {

                            ForEach(
                                Array(
                                    bluetooth.diagnosticEvents.prefix(10).enumerated()
                                ),
                                id: \.offset
                            ) { _, event in

                                Text(event)
                                    .font(.caption)
                                    .textSelection(.enabled)
                            }
                        }
                    }
                }
            }
            .padding()
            .navigationTitle("WatchBridge")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Informações do dispositivo

    private func deviceInformationValue(
        for uuid: String,
        label: String
    ) -> String {

        guard let characteristic = bluetooth.discoveredCharacteristics.first(
            where: {
                normalizeBluetoothUUID($0.uuid) == uuid
            }
        ) else {
            return "Não disponibilizado"
        }

        guard characteristic.isReadable else {
            return "Leitura não disponível"
        }

        if characteristic.value == "Ainda não consultada" {
            return "Aguardando leitura"
        }

        let prefix = "\(label): "

        if characteristic.value.hasPrefix(prefix) {

            return String(
                characteristic.value.dropFirst(prefix.count)
            )
        }

        return characteristic.value
    }

    // MARK: - Normalização de UUID

    private func normalizeBluetoothUUID(_ uuid: String) -> String {

        let normalized = uuid
            .uppercased()
            .replacingOccurrences(of: "-", with: "")

        if normalized.count == 4 {
            return normalized
        }

        let bluetoothBase = "00001000800000805F9B34FB"

        if normalized.count == 32,
           normalized.hasPrefix("0000"),
           normalized.hasSuffix(bluetoothBase) {

            return String(normalized.prefix(8).suffix(4))
        }

        return normalized
    }

    // MARK: - Indicador de capacidade

    private func capabilityLabel(
        _ title: String,
        enabled: Bool
    ) -> some View {

        Label(
            title,
            systemImage: enabled
                ? "checkmark.circle.fill"
                : "xmark.circle"
        )
        .font(.caption2)
        .foregroundStyle(
            enabled ? .green : .secondary
        )
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            enabled
                ? Color.green.opacity(0.10)
                : Color.gray.opacity(0.10)
        )
        .clipShape(Capsule())
    }
}
