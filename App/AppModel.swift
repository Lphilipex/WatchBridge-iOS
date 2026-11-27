
import Foundation
import Combine

@MainActor
final class AppModel: ObservableObject {

    // MARK: - Informações da interface

    @Published var status = "Iniciando…"
    @Published var lastHeartRate: Double?
    @Published var totalSteps: Double = 0
    @Published var log: [String] = []

    // MARK: - Serviços

    private let ble = BLEPeripheralService()
    private let health = HealthWriter()

    // MARK: - Controle de mensagens

    private var processingMessageIDs: Set<UInt16> = []

    private var processedMessageIDs: Set<UInt16> = []
    private var processedMessageOrder: [UInt16] = []

    private let maximumProcessedMessages = 256

    // MARK: - Inicialização

    init() {

        ble.onStatus = { [weak self] text in
            Task { @MainActor in
                self?.status = text
            }
        }

        ble.onMessage = { [weak self] message in
            Task { @MainActor in
                self?.handle(message)
            }
        }
    }

    // MARK: - Autorização do Apple Saúde

    func requestHealthAccess() {

        Task {
            do {

                try await health.requestAuthorization()

                append("Permissão do Saúde solicitada")

            } catch {

                append("Saúde: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Recebimento de mensagens

    private func handle(_ message: ReassembledMessage) {

        // Verificar se a mensagem já foi gravada.
        if processedMessageIDs.contains(message.id) {

            append("Mensagem \(message.id) já processada")

            // Reenviar o ACK sem gravar novamente.
            ble.sendAck(for: message.id)

            return
        }

        // Evitar processamento simultâneo do mesmo ID.
        if processingMessageIDs.contains(message.id) {

            append("Mensagem \(message.id) já está sendo processada")

            return
        }

        // Validar o conteúdo recebido.
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

            guard let batch = try? decoder.decode(
            HealthBatch.self,
            from: message.data
        ),
        batch.type == "health" else {

            append(
                "Mensagem desconhecida (\(message.data.count) bytes)"
            )

            return
        }

        guard !batch.samples.isEmpty else {

            append("Lote recebido sem amostras")

            return
        }

        // Marcar como em processamento.
        processingMessageIDs.insert(message.id)

        Task {

            do {

                // Gravar os dados no Apple Saúde.
                try await health.save(batch.samples)

                // Remover da lista de processamento.
                processingMessageIDs.remove(message.id)

                // Registrar como processada.
                registerProcessedMessage(message.id)

                // Atualizar informações da interface.
                if let heartRate = batch.samples.last(
                    where: { $0.kind == .heartRate }
                ) {

                    lastHeartRate = heartRate.value
                }

                totalSteps += batch.samples
                    .filter { $0.kind == .steps }
                    .reduce(0) { $0 + $1.value }

                append(
                    "Gravadas \(batch.samples.count) amostras"
                )

                // Confirmar somente depois da gravação.
                ble.sendAck(for: message.id)

            } catch {

                // Permitir nova tentativa após falha.
                processingMessageIDs.remove(message.id)

                append(
                    "Erro ao gravar: \(error.localizedDescription)"
                )
            }
        }
    }

    // MARK: - Registro de mensagens processadas

    private func registerProcessedMessage(_ id: UInt16) {

        guard !processedMessageIDs.contains(id) else {
            return
        }

        processedMessageIDs.insert(id)
        processedMessageOrder.append(id)

        // Manter somente os últimos 256 IDs.
        while processedMessageOrder.count > maximumProcessedMessages {

            let oldestID = processedMessageOrder.removeFirst()

            processedMessageIDs.remove(oldestID)
        }
    }

    // MARK: - Histórico

    private func append(_ line: String) {

        log.insert(
            "\(Date().formatted(date: .omitted, time: .standard))  \(line)",
            at: 0
        )

        if log.count > 100 {
            log.removeLast()
        }
    }
}
