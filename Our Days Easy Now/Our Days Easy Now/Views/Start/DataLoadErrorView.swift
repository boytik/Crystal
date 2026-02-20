// DataLoadErrorView.swift
// Our Days: Easy Now
// Error screen when JSON load fails — with Retry button

import SwiftUI

struct DataLoadErrorView: View {
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 56))
                .foregroundColor(NestPalette.candleAmber)

            Text("Something went wrong")
                .font(.title2.weight(.bold))
                .foregroundColor(NestPalette.snowfall)

            Text("We couldn't load your data. Your information is safe on this device.")
                .font(.subheadline)
                .foregroundColor(NestPalette.duskWhisper)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button(action: onRetry) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Retry")
                }
            }
            .buttonStyle(HearthButtonStyle())
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(NestPalette.emberNight)
    }
}
