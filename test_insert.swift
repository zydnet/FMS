import Foundation

let url = URL(string: "https://ejobygxvjknihqbjcrku.supabase.co/rest/v1/vehicle_documents")!
var request = URLRequest(url: url)
request.httpMethod = "POST"
request.addValue("Bearer process.env.SUPABASE_ANON_KEY", forHTTPHeaderField: "Authorization") // Wait, I need to get anon key from config!
