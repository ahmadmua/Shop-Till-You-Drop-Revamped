//
//  ProductInfo.swift
//  ShopTillYouDrop
//
//  Created by Muaz on 2024-03-29.
//

import SwiftUI
import Amplify
import Foundation

struct ProductDetailView: View {
    
    var product: Product

    @EnvironmentObject var userState: UserState
    
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedImageIndex: Int = 0
    @State private var isAutomaticAnimationEnabled = true
    @State private var isHeartFilled = false
    @State private var offers: [OffersProductData] = []
    
    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                AsyncImage(url: URL(string: product.product_photos[selectedImageIndex])) { image in
                    image.image?.resizable().scaledToFit()
                        .frame(width: 400, height: 400)
                }
                .frame(maxHeight: 350)
                .animation(isAutomaticAnimationEnabled ? .easeInOut(duration: 0.5) : nil) // Add conditional animation here
                
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 10) {
                        ForEach(product.product_photos.indices, id: \.self) { index in
                            Button(action: {
                                withAnimation {
                                    isAutomaticAnimationEnabled = false
                                    selectedImageIndex = index
                                }
                            }) {
                                AsyncImage(url: URL(string: product.product_photos[index])) { image in
                                    image.image?
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 80, height: 80)
                                }
                                .frame(width: 80, height: 80)
                                .padding(.top, 15)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    
                    HStack {
                        
                        Text(product.product_title)
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 4)
                        
                        Button(action: {
                            isHeartFilled.toggle()
                            Task {
                                
                                await createProductData()
                                
                            }
                        }) {
                            Image(systemName: isHeartFilled ? "heart.fill" : "heart").resizable()
                                .frame(width: 27, height: 27)
                                .foregroundColor(.red)
                                .padding(.leading, 5)
                        }
                        
                        
                        
                    }
                    
                    HStack {
                        
                        Text(product.offer.price ?? "N/A")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                            .padding(.trailing)
                        
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .frame(width: 9, height: 9)
                        
                        Text("\(String(format: "%.2f", product.product_rating ?? 0.0))")
                            .font(.subheadline)
                            .foregroundColor(.black)
                        
                    }
                    HStack {
                        
                        Text("SOLD BY:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            if let url = URL(string: product.offer.offer_page_url!) {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Text(product.offer.store_name ?? "N/A")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Divider()
                    
                    Text("Description")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    Text(product.product_description ?? "N/A")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 4)
                    
                    Text("Compare Price")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    ScrollView(.horizontal) {
                        HStack(spacing: 20) {
                            ForEach(offers, id: \.offer_page_url) { offer in
                                Button(action: {
                                    if let url = URL(string: offer.offer_page_url) {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    
                                    Text("\(offer.store_name)\n \(offer.price)")
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                            }
                        }
                        .padding()
                    }
                    
                }
                .padding(.horizontal)
            }
            .padding(.top)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(timer) { _ in
            guard isAutomaticAnimationEnabled else { return }
            let newIndex = (selectedImageIndex + 1) % product.product_photos.count
            withAnimation {
                selectedImageIndex = newIndex
            }
        }
        //.onAppear(perform: fetchOfferData)
    }
    
    func createProductData() async {
        
        do{

            let model = ProductDataState(
                product_id: product.product_id,
                product_title: product.product_title,
                userId: userState.userId,
                product_description: product.product_description,
                product_rating: product.product_rating,
                offer: OfferDataState(store_name: product.offer.store_name, price: product.offer.price, offer_page_url: product.offer.offer_page_url),
                product_photos: product.product_photos

            )
            
            
            let savedProduct = try await Amplify.DataStore.save(model)
            //print("Saved product: \(savedProduct)")
            
        }catch{
            print(error)
        }
        
    }
    
    
        
    
    
    func fetchOfferData() {
        let headers = [
            "X-RapidAPI-Key": "2f97e8506bmsh25356e3490e7c7bp1344f9jsn7720690c277c",
            "X-RapidAPI-Host": "real-time-product-search.p.rapidapi.com"
        ]
        
        let urlString = "https://real-time-product-search.p.rapidapi.com/product-offers?product_id=\(product.product_id)&country=ca&language=en"
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        let request = NSMutableURLRequest(url: url,
                                          cachePolicy: .useProtocolCachePolicy,
                                          timeoutInterval: 10.0)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest) { (data, response, error) in
            if let error = error {
                print("Error: \(error)")
            } else {
                if let data = data {
                    do {
                        let decodedData = try JSONDecoder().decode(OffersResponse.self, from: data)
                        DispatchQueue.main.async {
                            self.offers = decodedData.data.offers
                            //print(self.offers)
                        }
                    } catch {
                        print("Error decoding JSON: \(error)")
                    }
                }
            }
        }
        
        dataTask.resume()
    }
    
    
    
    
}





//
//struct ProductDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        let product = ProductData(product_id: "1",
//                                  product_title: "Nike Retro A1",
//                                  product_rating: 4.5, product_description: "The Nike Dunk Low Retro White Black (PS) sneakers combine iconic style with modern comfort. With its timeless white and black colorway, these sneakers are versatile and perfect for any occasion. The retro design pays homage to the original Nike Dunk, while the low-top silhouette offers a contemporary vibe. Crafted with premium materials, these sneakers provide durability and support. Whether you're hitting the skate park or strolling the streets, the Nike Dunk Low Retro White Black (PS) sneakers will elevate your footwear game",
//                                  offer: Offer(store_name: "Amazon", price: "$19.99", offer_page_url: "TEST URL"))
//        return ProductDetailView(product: product)
//    }
//}
