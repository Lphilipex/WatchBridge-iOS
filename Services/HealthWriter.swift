
import Foundation
import HealthKit

// MARK: - Gravação de dados no Apple Saúde

final class HealthWriter {

    private let healthStore = HKHealthStore()

    // MARK: - Solicitar autorização

    func requestAuthorization() async throws {

        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthWriterError.healthDataUnavailable
        }

        guard let heartRateType = HKObjectType.quantityType(
            forIdentifier: .heartRate
        ),
        let stepsType = HKObjectType.quantityType(
            forIdentifier: .stepCount
        ) else {
            throw HealthWriterError.invalidHealthType
        }

        let typesToShare: Set<HKSampleType> = [
            heartRateType,
            stepsType
        ]

        try await healthStore.requestAuthorization(
            toShare: typesToShare,
            read: []
        )
    }

    // MARK: - Salvar amostras

    func save(_ samples: [HealthSample]) async throws {

        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthWriterError.healthDataUnavailable
        }

        // Não permitir lotes vazios.
        guard !samples.isEmpty else {
            throw HealthWriterError.invalidSample
        }

        var healthSamples: [HKQuantitySample] = []

        for sample in samples {

            // Validar datas e valores.
            guard sample.startDate <= sample.endDate,
                  sample.value.isFinite,
                  sample.value >= 0 else {

                throw HealthWriterError.invalidSample
            }

            // Frequência cardíaca precisa ser maior que zero.
            if sample.kind == .heartRate && sample.value <= 0 {
                throw HealthWriterError.invalidSample
            }

            // Passos precisam ser inteiros e ter intervalo válido.
            if sample.kind == .steps {

                guard sample.startDate < sample.endDate,
                      sample.value.rounded(.towardZero) == sample.value else {

                    throw HealthWriterError.invalidSample
                }
            }

            let quantityType: HKQuantityType
            let unit: HKUnit

            switch sample.kind {

            case .heartRate:

                guard let type = HKObjectType.quantityType(
                    forIdentifier: .heartRate
                ) else {
                    throw HealthWriterError.invalidHealthType
                }

                quantityType = type
                unit = HKUnit.count().unitDivided(
                    by: HKUnit.minute()
                )

            case .steps:

                guard let type = HKObjectType.quantityType(
                    forIdentifier: .stepCount
                ) else {
                    throw HealthWriterError.invalidHealthType
                }

                quantityType = type
                unit = HKUnit.count()
            }

            // Criar quantidade para o Apple Saúde.
            let quantity = HKQuantity(
                unit: unit,
                doubleValue: sample.value
            )

            let healthSample = HKQuantitySample(
                type: quantityType,
                quantity: quantity,
                start: sample.startDate,
                end: sample.endDate
            )

            healthSamples.append(healthSample)
        }

        // Gravar todas as amostras.
        try await healthStore.save(healthSamples)
    }
}

// MARK: - Erros

enum HealthWriterError: LocalizedError {

    case healthDataUnavailable
    case invalidHealthType
    case invalidSample

    var errorDescription: String? {

        switch self {

        case .healthDataUnavailable:
            return "O Apple Saúde não está disponível neste dispositivo."

        case .invalidHealthType:
            return "Não foi possível identificar o tipo de dado de saúde."

        case .invalidSample:
            return "A amostra possui valores ou datas inválidas."
        }
    }
}
