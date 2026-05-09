import SwiftUI

struct HalfCourtShape: View {
    var body: some View {
        GeometryReader { geo in
            Image("court")
                .resizable()
                .scaledToFill()
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}
