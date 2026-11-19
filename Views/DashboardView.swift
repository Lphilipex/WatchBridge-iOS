
import SwiftUI

struct DashboardView: View {

    @StateObject private var bluetooth = BluetoothManager()

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

                    // MARK: Dispositivos encontrados

                    Section("Dispositivos encontrados") {

                        if bluetooth.devices.isEmpty {

                            Text("Nenhum dispositivo encontrado")
                                .foregroundStyle(.secondary)

                        } else {

                            ForEach(bluetooth.devices) { device in

                                Button {
                                    bluetooth.connect(to: device)
                                } label: {

                                    VStack(alignment: .leading, spacing: 7) {

                                        HStack {

                                            Text(device.name)
                                                .font(.headline)
                                                .foregroundStyle(.primary)

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

                                        Text(device.id.uuidString)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                            .textSelection(.enabled)

                                        HStack {

                                            Label(
                                                "\(device.rssi) dBm",
                                                systemImage: "wifi"
                                            )

                                            Spacer()

                                            Text("Toque para conectar")
                                                .foregroundStyle(.blue)
                                        }
                                        .font(.caption)
                                    }
                                    .padding(.vertical, 4)
                                }
                                .disabled(
                                    bluetooth.isConnected ||
                                    bluetooth.isConnecting
                                )
                            }
                        }
                    }

                    // MARK: - Serviços GATT

                    if bluetooth.isConnected {

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

                                            Text(
                                                characteristic.serviceName
                                            )
                                            .font(.subheadline)

                                            Text(
                                                characteristic.serviceUUID
                                            )
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
                                                    enabled: characteristic.isWritable
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

                                        // Ações

                                        VStack(
                                            alignment: .leading,
                                            spacing: 8
                                        ) {

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
