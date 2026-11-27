
import Foundation

// MARK: - Tipo de dado de saúde

enum HealthSampleKind: String, Codable {
    case heartRate
    case steps
}

// MARK: - Amostra de saúde

struct HealthSample: Codable {
    let kind: HealthSampleKind
    let value: Double
    let startDate: Date
    let endDate: Date
}

// MARK: - Lote de dados de saúde

struct HealthBatch: Codable {
    let type: String
    let samples: [HealthSample]
}
