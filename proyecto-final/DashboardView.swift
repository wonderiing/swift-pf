import SwiftUI

struct DashboardView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    
                    // HEADER con gradiente
                    ZStack(alignment: .leading) {
                        LinearGradient(gradient: Gradient(colors: [.blue, .purple]),
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing)
                            .frame(height: 180)
                            .cornerRadius(20)
                            .shadow(radius: 5)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Bienvenido 👋")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.9))
                            Text("Tu Dashboard")
                                .font(.largeTitle)
                                .bold()
                                .foregroundColor(.white)
                        }
                        .padding()
                    }
                    .padding(.horizontal)
                    
                    
                    // STATS en tarjetas verticales
                    VStack(spacing: 20) {
                        StatVerticalCard(title: "Archivos Totales",
                                         value: "3",
                                         color: .blue,
                                         icon: "doc.on.doc")
                        
                        StatVerticalCard(title: "Auditorías Completadas",
                                         value: "0",
                                         color: .green,
                                         icon: "checkmark.circle")
                        
                        StatVerticalCard(title: "Pendientes de Revisión",
                                         value: "3",
                                         color: .yellow,
                                         icon: "clock")
                    }
                    .padding(.horizontal)
                    
                    
                    // SECCIÓN DE UPLOAD
                    VStack(spacing: 16) {
                        Text("Subir Documento")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.gray.opacity(0.05))
                            .frame(height: 200)
                            .overlay(
                                VStack(spacing: 12) {
                                    Image(systemName: "arrow.up.doc.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(.blue)
                                        .padding(.bottom, 8)
                                    
                                    Text("Haz clic para seleccionar o arrastra tu archivo")
                                        .font(.subheadline)
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(.blue)
                                        .padding(.horizontal, 20)
                                    
                                    Button(action: {
                                        print("Seleccionar archivo")
                                    }) {
                                        Text("Seleccionar Archivo")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .padding()
                                            .frame(maxWidth: .infinity)
                                            .background(Color.blue)
                                            .cornerRadius(12)
                                            .shadow(radius: 3)
                                    }
                                    .padding(.horizontal, 40)
                                }
                            )
                            .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .padding(.top)
            }
            .navigationBarHidden(true)
        }
    }
}


/// Tarjeta vertical para stats
struct StatVerticalCard: View {
    var title: String
    var value: String
    var color: Color
    var icon: String
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(color)
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.gray)
                    Text(value)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(color)
                }
                Spacer()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 5, x: 0, y: 4)
    }
}

#Preview {
    DashboardView()
}

