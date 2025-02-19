import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var viewModel = UnsplashViewModel()
    @State private var searchText = ""

    var body: some View {
        TabView {
            ImageGridView(title: "Unsplash Images", images: viewModel.filteredImages(searchText), viewModel: viewModel)
                .tabItem {
                    Label("Home", systemImage: "photo.on.rectangle.angled")
                }
            
            ImageGridView(title: "Favorites", images: viewModel.favorites, viewModel: viewModel)
                .tabItem {
                    Label("Favorites", systemImage: "heart.fill")
                }
        }
        .onAppear {
            viewModel.fetchImages()
        }
    }
}

struct ImageGridView: View {
    let title: String
    let images: [UnsplashImage]
    @ObservedObject var viewModel: UnsplashViewModel
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            VStack {
                if title == "Unsplash Images" {
                    SearchBar(text: $searchText)
                }

                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(images) { image in
                            NavigationLink(destination: ImageDetailView(image: image, viewModel: viewModel)) {
                                ImageCard(image: image)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(title)
        }
    }
}

struct ImageCard: View {
    let image: UnsplashImage

    var body: some View {
        VStack {
            AsyncImage(url: URL(string: image.urls.small)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure:
                    Image(systemName: "photo").foregroundColor(.gray)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 150, height: 200)
            .clipped()
            .cornerRadius(15)

            Text(image.user.name.components(separatedBy: " ").prefix(2).joined(separator: " "))
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

struct ImageDetailView: View {
    let image: UnsplashImage
    @ObservedObject var viewModel: UnsplashViewModel

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
                    Image(systemName: "photo").foregroundColor(.gray)
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

            HStack {
                Button(action: {
                    viewModel.toggleFavorite(image)
                }) {
                    Image(systemName: viewModel.isFavorite(image) ? "heart.fill" : "heart")
                        .foregroundColor(viewModel.isFavorite(image) ? .red : .gray)
                        .font(.largeTitle)
                }
                .padding()

                Button(action: {
                    shareImage(image.urls.regular)
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.largeTitle)
                }
                .padding()
            }
        }
        .padding()
        .navigationTitle("Image Details")
    }

    func shareImage(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first,
           let rootViewController = window.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
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
    @Published var favorites: [UnsplashImage] = []
    private let accessKey = "6tiEqEExO_0ao5AvBBG5RfeME8FRwn03gyNOtz5HLI4"

    func fetchImages() {
        guard let url = URL(string: "https://api.unsplash.com/photos/?client_id=\(accessKey)") else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
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

    func toggleFavorite(_ image: UnsplashImage) {
        if isFavorite(image) {
            favorites.removeAll { $0.id == image.id }
        } else {
            favorites.append(image)
        }
    }

    func isFavorite(_ image: UnsplashImage) -> Bool {
        favorites.contains { $0.id == image.id }
    }

    func filteredImages(_ query: String) -> [UnsplashImage] {
        guard !query.isEmpty else { return images }
        return images.filter { $0.user.name.lowercased().contains(query.lowercased()) }
    }
}

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            TextField("Search by photographer...", text: $text)
                .padding(7)
                .background(Color(.systemGray6))
                .cornerRadius(10)
        }
        .padding(.horizontal)
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
