import Foundation
import Alamofire

nonisolated struct PlaceDTO: Decodable, Sendable {
    let lat: String
    let lon: String
    let displayName: String

    enum CodingKeys: String, CodingKey {
        case lat
        case lon
        case displayName = "display_name"
    }
}

nonisolated struct SearchResult: Sendable {
    let name: String
    let lat: Double
    let lon: Double
}

struct MapClient {

    func searchDirection(_ text: String) async throws -> SearchResult? {
        let urlString = "https://nominatim.openstreetmap.org/search"
        
        let parameters: [String: String] = [
            "q": text,
            "format": "json",
            "limit": "1"
        ]
        
        let headers: HTTPHeaders = [
            "User-Agent": "RemindersApp/1.0"
        ]
        
        let places: [PlaceDTO] = try await AF.request(urlString, parameters: parameters, headers: headers)
            .validate()
            .serializingDecodable([PlaceDTO].self)
            .value

        guard let firstPlace = places.first,
              let lat = Double(firstPlace.lat),
              let lon = Double(firstPlace.lon) else {
            return nil
        }

        return SearchResult(
            name: firstPlace.displayName,
            lat: lat,
            lon: lon
        )
    }
}
