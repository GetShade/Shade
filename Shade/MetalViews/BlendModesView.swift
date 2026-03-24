//
//  BlendModesView.swift
//  Shade
//
//  Created by Ahmed Ragab on 04/01/2025.
//


import SwiftUI
import Metal

struct BlendModesView: View {
    @State private var selectedMode: BlendMode = .normal
    
    let blendModes: [(name: String, mode: BlendMode)] = [
        ("Normal", .normal),
        ("Color Dodge", .colorDodge),
        ("Hard Mix", .hardLight),
        ("Darken", .darken),
        ("Linear Dodge", .plusLighter),
        ("Difference", .difference),
        ("Multiply", .multiply),
        ("Lighter Color", .lighten),
        ("Exclusion", .exclusion),
        ("Color Burn", .colorBurn),
        ("Overlay", .overlay),
        ("Subtract", .difference),
        ("Linear Burn", .colorBurn),
        ("Soft Light", .softLight),
        ("Divide", .screen),
        ("Darker", .darken),
        ("Hard Light", .hardLight),
        ("Hue", .hue),
        ("Color", .color),
        ("Vivid Light", .hardLight),
        ("Saturation", .saturation),
        ("Lighten", .lighten),
        ("Linear Light", .plusLighter),
        ("Screen", .screen),
        ("Pin Light", .hardLight)
    ]
    
    var body: some View {        
            VStack(spacing: 16) {
                // Preview Area
                ZStack {
                    Image(.person)
  
                        Image(.city)
                        
                        .blendMode(selectedMode)
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .shadow(radius: 10)
                .padding(.horizontal)
                
                // Current Selection Display
                Text("Selected: \(blendModes.first(where: { $0.mode == selectedMode })?.name ?? "Normal")")
                    .font(.headline)
                    .padding(.vertical, 8)
                
                // Blend Mode Picker using List
                List {
                    ForEach(blendModes, id: \.name) { blendMode in
                        HStack {
                            Text(blendMode.name)
                                .font(.system(.body))
                            Spacer()
                            if selectedMode == blendMode.mode {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation {
                                selectedMode = blendMode.mode
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(PlainListStyle())
            }
    }
}

// Preview Provider
struct BlendModesView_Previews: PreviewProvider {
    static var previews: some View {
        BlendModesView()
    }
}
