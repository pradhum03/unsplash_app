import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = UnsplashViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(viewModel.images) { image in
                        NavigationLink(destination: ImageDetailView(image: image)) {
                            VStack {
                                AsyncImage(url: URL(string: image.urls.small)) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                    case .success(let image):
                                        image.resizable().scaledToFill()
                                    case .failure:
                                        Image(systemName: "photo")
                                            .foregroundColor(.gray)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                                .frame(height: 120)
                                .clipped()
                                .cornerRadius(15)
                                
                                Text(image.user.name)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 5)
                            }
                            .padding(8)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(radius: 4)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Unsplash Images")
        }
        .onAppear {
            viewModel.fetchImages()
        }
    }
}

struct ImageDetailView: View {
    let image: UnsplashImage
    
    var body: some View {
        VStack {
            AsyncImage(url: URL(string: image.urls.regular)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    image.resizable().scaledToFit()
                        .cornerRadius(15)
                        .shadow(radius: 5)
                case .failure:
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(height: 500)
            .padding()
            
            Text("Photographer: \(image.user.name)")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top, 10)
        }
        .padding()
        .navigationTitle("Image Details")
    }
}

struct UnsplashImage: Codable, Identifiable {
    let id: String
    let urls: ImageURLs
    let user: User
}

struct ImageURLs: Codable {
    let small: String
    let regular: String
}

struct User: Codable {
    let name: String
}

class UnsplashViewModel: ObservableObject {
    @Published var images: [UnsplashImage] = []
    private let accessKey = "g1pqQyBlzemJFgjw3lNKoXS0J9GuuIOsFQWmEcWGc_8"
    
    func fetchImages() {
        guard let url = URL(string: "https://api.unsplash.com/photos/?client_id=\(accessKey)") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else { return }
            
            do {
                let images = try JSONDecoder().decode([UnsplashImage].self, from: data)
                DispatchQueue.main.async {
                    self.images = images
                }
            } catch {
                print("Failed to decode JSON: \(error)")
            }
        }.resume()
    }
}

@main
struct UnsplashApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

