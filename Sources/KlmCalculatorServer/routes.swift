import Vapor
import Persona

// Response payload
struct KLMTimeResponse: Content {
    let estimatedTime: Double?
    let message: String
}

// Map your domain errors to user-facing messages
private func klmMessage(for error: KLMError) -> String {
    switch error {
    case .unknownOperator(let tok):
        return "Unknown operator: \(tok). Allowed: K, P, H, M, B (or parameterized P_...)."
    case .malformedResponse(let tok):
        return "Malformed response token: \(tok). Use R(0.5) style."
    case .missingFittsParams(let tok):
        return "Missing Fitts' Law params in \(tok). Provide distance and width, e.g. P_distance:200;width:40."
    case .nonPositiveFittsParams(let tok):
        return "Fitts' Law params must be > 0 in \(tok)."
    }
}

// Supported platforms
private enum Platform: String {
    case desktop, mobile, watch

    init?(raw: String?) {
        guard let v = raw?.lowercased() else { self = .desktop; return } // default to desktop
        if let p = Platform(rawValue: v) {
            self = p
        } else {
            return nil
        }
    }
}

// Factory for the proper Persona user
private func klmUser(for platform: Platform) -> any InterfaceUser {
    switch platform {
    case .desktop: return DesktopUser()
    case .mobile:  return DesktopUser()
    case .watch:   return WatchUser()
    }
}

func routes(_ app: Application) throws {

    // Root serves the Public/index.html file
   app.get { req async throws -> Response in
       let path = req.application.directory.publicDirectory + "index.html"
       return try await req.fileio.asyncStreamFile(at: path)
   }


    app.get("api", "lm") { req async throws -> Response in
        // Validate required query ?q=...
        guard let action: String = try? req.query.get(String.self, at: "q"),
              action.isEmpty == false
        else {
            let payload = KLMTimeResponse(
                estimatedTime: nil,
                message: "Missing required query parameter 'q'. Example: ?q=M,P_distance:200;width:40,B,B"
            )
            let res = Response(status: .badRequest)
            try res.content.encode(payload, as: .json)
            return res
        }
    
        // Parse platform (defaults to desktop if absent/empty; error if unknown token provided)
        let platformParam: String? = try? req.query.get(String.self, at: "platform")
        guard let platform = Platform(raw: platformParam) else {
            let payload = KLMTimeResponse(
                estimatedTime: nil,
                message: "Invalid platform: \(platformParam ?? ""). Allowed: desktop, mobile, watch."
            )
            let res = Response(status: .badRequest)
            try res.content.encode(payload, as: .json)
            return res
        }
    
        do {
            let user = klmUser(for: platform)
            let t = try user.taskTime(for: action)
            let payload = KLMTimeResponse(estimatedTime: t, message: "ok")
            let res = Response(status: .ok)
            try res.content.encode(payload, as: .json)
            return res
        } catch let e as KLMError {
            let payload = KLMTimeResponse(estimatedTime: nil, message: klmMessage(for: e))
            let res = Response(status: .unprocessableEntity) // 422 for domain/validation errors
            try res.content.encode(payload, as: .json)
            return res
        } catch {
            let payload = KLMTimeResponse(estimatedTime: nil, message: "Unexpected error: \(error)")
            let res = Response(status: .internalServerError)
            try res.content.encode(payload, as: .json)
            return res
        }
    }
}