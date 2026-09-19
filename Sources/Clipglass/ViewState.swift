import SwiftUI
// Use the property wrapper on SDKs whose optional State macro plugin is absent.
typealias ViewState<Value> = SwiftUICore.State<Value>
