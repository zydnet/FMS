import Foundation

let semaphore = DispatchSemaphore(value: 0)

let url = URL(string: "https://ejobygxvjknihqbjcrku.supabase.co/rest/v1/vehicle_documents")!
var request = URLRequest(url: url)
request.httpMethod = "POST"
request.addValue("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVqb2J5Z3h2amtuaWhxYmpjcmt1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTEwOTI4MzYsImV4cCI6MjAyNjY2ODgzNn0.abc", forHTTPHeaderField: "Authorization") // This is intentionally fake, wait, I can just use curl with the exact anon key and user jwt
// it's easier to just print the exact error using a tiny Swift program that imports Supabase.

