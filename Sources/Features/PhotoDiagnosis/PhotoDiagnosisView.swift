import SwiftUI
import PhotosUI
import SwiftData

struct PhotoDiagnosisView: View {
    @StateObject private var vm = PhotoDiagnosisViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var pickerItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var showAnnotation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Image preview
                    ZStack(alignment: .bottomTrailing) {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemBackground))
                            .frame(height: 260)
                        if let img = vm.selectedImage {
                            Image(uiImage: img)
                                .resizable().scaledToFill()
                                .frame(height: 260)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            // Annotate button overlay
                            Button {
                                showAnnotation = true
                            } label: {
                                Label("Annotate", systemImage: "pencil.tip.crop.circle")
                                    .font(.caption.bold())
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(.ultraThinMaterial, in: Capsule())
                            }
                            .padding(10)
                        } else {
                            VStack(spacing: 10) {
                                Image(systemName: "camera.viewfinder")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.blue)
                                Text("Take or select a photo")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Action buttons
                    HStack(spacing: 12) {
                        Button {
                            showCamera = true
                        } label: {
                            Label("Camera", systemImage: "camera.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)

                        PhotosPicker(selection: $pickerItem, matching: .images) {
                            Label("Gallery", systemImage: "photo.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.horizontal)

                    // Trade type picker
                    Picker("Trade", selection: $vm.trade) {
                        ForEach(TradeType.allCases) { t in
                            Text(t.label).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Analyse button
                    Button {
                        Task { await vm.analyse() }
                    } label: {
                        HStack {
                            if vm.isLoading {
                                ProgressView().tint(.white)
                            }
                            Text(vm.isLoading ? "Analysing…" : "Analyse")
                                .bold()
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .disabled(vm.selectedImage == nil || vm.isLoading)
                    .padding(.horizontal)

                    // Result
                    if !vm.result.isEmpty {
                        ResultCard(text: vm.result)
                            .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Photo Diagnosis")
            .onChange(of: pickerItem) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self),
                       let img  = UIImage(data: data) {
                        vm.selectedImage = img
                    }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraView(image: $vm.selectedImage)
            }
            .fullScreenCover(isPresented: $showAnnotation) {
                if let img = vm.selectedImage {
                    PhotoAnnotationView(baseImage: img) { annotated in
                        vm.selectedImage = annotated
                    }
                }
            }
            .onAppear { vm.modelContext = modelContext }
            .alert("Error", isPresented: $vm.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(vm.errorMessage)
            }
        }
    }
}
