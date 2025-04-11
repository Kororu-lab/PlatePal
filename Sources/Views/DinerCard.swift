// Debug information - more explicitly check debug mode status
if viewModel.isDebugMode == true || localDebugMode == true {
    VStack(alignment: .leading, spacing: 2) {
        Text("Score: \(String(format: "%.2f", score ?? 0))")
            .font(.caption)
            .foregroundColor(.white)
        
        Text("Category Match: \(String(format: "%.2f", categorySimilarity ?? 0))")
            .font(.caption)
            .foregroundColor(.white)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 4)
    .padding(.horizontal, 6)
    .background(Color.blue)
    .cornerRadius(4)
} 