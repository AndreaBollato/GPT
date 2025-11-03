import Foundation

enum HTTPMethod: String {
    case GET, POST, PATCH, DELETE
}

struct Endpoint {
    var path: String
    var method: HTTPMethod
    var query: [URLQueryItem] = []
    var body: Encodable?
    var headers: [String: String] = [:]
    
    init(path: String, method: HTTPMethod, query: [URLQueryItem] = [], body: Encodable? = nil, headers: [String: String] = [:]) {
        self.path = path
        self.method = method
        self.query = query
        self.body = body
        self.headers = headers
    }
}

enum HTTPError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, data: Data?)
    case decodingError(Error)
    case networkError(Error)
    case encodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode, _):
            return "HTTP error: \(statusCode)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        }
    }
}

struct HTTPClient {
    let baseURL: URL
    let session: URLSession
    let decoder: JSONDecoder
    let encoder: JSONEncoder
    
    init(baseURL: URL, 
         session: URLSession = .shared,
         decoder: JSONDecoder = APIDecoders.default,
         encoder: JSONEncoder = APIDecoders.encoder) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = decoder
        self.encoder = encoder
    }
    
    /// Performs a request and decodes the response
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let urlRequest = try makeRequest(endpoint)
        
        do {
            let (data, response) = try await session.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw HTTPError.invalidResponse
            }
            
            guard (200..<300).contains(httpResponse.statusCode) else {
                throw HTTPError.httpError(statusCode: httpResponse.statusCode, data: data)
            }
            
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw HTTPError.decodingError(error)
            }
        } catch let error as HTTPError {
            throw error
        } catch {
            throw HTTPError.networkError(error)
        }
    }
    
    /// Performs a request that returns no content (e.g., 204 No Content)
    func requestVoid(_ endpoint: Endpoint) async throws {
        let urlRequest = try makeRequest(endpoint)
        
        do {
            let (_, response) = try await session.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw HTTPError.invalidResponse
            }
            
            guard (200..<300).contains(httpResponse.statusCode) else {
                throw HTTPError.httpError(statusCode: httpResponse.statusCode, data: nil)
            }
        } catch let error as HTTPError {
            throw error
        } catch {
            throw HTTPError.networkError(error)
        }
    }
    
    /// Creates a URLRequest from an endpoint (used by SSE client)
    func makeRequest(_ endpoint: Endpoint) throws -> URLRequest {
        var urlComponents = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: true)
        
        if !endpoint.query.isEmpty {
            urlComponents?.queryItems = endpoint.query
        }
        
        guard let url = urlComponents?.url else {
            throw HTTPError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        
        // Set headers
        for (key, value) in endpoint.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Encode body if present
        if let body = endpoint.body {
            do {
                request.httpBody = try encoder.encode(body)
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            } catch {
                throw HTTPError.encodingError(error)
            }
        }
        
        return request
    }
}
