import SwiftUI

// MARK: - Customer Model
struct Customer: Identifiable, Codable, Hashable, Equatable {
    var id = UUID()
    var name: String
    var contact: String
    var address: String
}

// MARK: - Order Model
struct Order: Identifiable, Codable, Hashable, Equatable {
    var id = UUID()
    var customerId: UUID
    var itemType: String
    var quantity: Int
    var serviceType: String
    var status: String
    var orderDate: Date
}

// MARK: - Payment Model
struct Payment: Identifiable, Codable, Hashable, Equatable {
    var id = UUID()
    var orderId: UUID
    var amount: Double
    var paymentDate: Date
    var paymentStatus: String
    var paymentMethod: String
}

// MARK: - CleanMasterViewModel
class CleanMasterViewModel: ObservableObject {
    @Published var customers: [Customer] = []
    @Published var orders: [Order] = []
    @Published var payments: [Payment] = []
    @Published var showAlert = false
    @Published var alertMessage = ""

    init() {
        loadCustomers()
        loadOrders()
        loadPayments()
    }

    // Customer functions
    func addCustomer(customer: Customer) {
        customers.append(customer)
        saveCustomers()
    }

    func deleteCustomer(at indexSet: IndexSet) {
        customers.remove(atOffsets: indexSet)
        saveCustomers()
    }

    func loadCustomers() {
        if let data = UserDefaults.standard.data(forKey: "Customers") {
            if let decoded = try? JSONDecoder().decode([Customer].self, from: data) {
                self.customers = decoded
            }
        }
    }

    func saveCustomers() {
        if let encoded = try? JSONEncoder().encode(customers) {
            UserDefaults.standard.set(encoded, forKey: "Customers")
        }
    }

    // Order functions
    func addOrder(order: Order) {
        orders.append(order)
        saveOrders()
    }

    func deleteOrder(at indexSet: IndexSet) {
        orders.remove(atOffsets: indexSet)
        saveOrders()
    }

    func loadOrders() {
        if let data = UserDefaults.standard.data(forKey: "Orders") {
            if let decoded = try? JSONDecoder().decode([Order].self, from: data) {
                self.orders = decoded
            }
        }
    }

    func saveOrders() {
        if let encoded = try? JSONEncoder().encode(orders) {
            UserDefaults.standard.set(encoded, forKey: "Orders")
        }
    }

    // Payment functions
    func addPayment(payment: Payment) {
        payments.append(payment)
        savePayments()
    }

    func deletePayment(at indexSet: IndexSet) {
        payments.remove(atOffsets: indexSet)
        savePayments()
    }

    func loadPayments() {
        if let data = UserDefaults.standard.data(forKey: "Payments") {
            if let decoded = try? JSONDecoder().decode([Payment].self, from: data) {
                self.payments = decoded
            }
        }
    }

    func savePayments() {
        if let encoded = try? JSONEncoder().encode(payments) {
            UserDefaults.standard.set(encoded, forKey: "Payments")
        }
    }
}

// MARK: - Customer List View



struct SearchBar: UIViewRepresentable {
    @Binding var text: String

    class Coordinator: NSObject, UISearchBarDelegate {
        @Binding var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            text = searchText
        }

        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            searchBar.resignFirstResponder()  // Dismiss the keyboard when the search button is pressed
        }

        func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
            searchBar.resignFirstResponder()  // Dismiss the keyboard when the cancel button is pressed
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(text: $text)
    }

    func makeUIView(context: Context) -> UISearchBar {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.delegate = context.coordinator
        searchBar.showsCancelButton = true  // Show a cancel button to allow dismissing the keyboard easily
        return searchBar
    }

    func updateUIView(_ uiView: UISearchBar, context: Context) {
        uiView.text = text
    }
}

struct CustomerListView: View {
    @ObservedObject var viewModel: CleanMasterViewModel
    @State private var searchQuery = ""
    @State private var showingAddCustomerForm = false
    @State private var showingDeleteAlert = false
    @State private var customerToDelete: Customer?

    var body: some View {
        NavigationView {
            VStack {
                // Search bar always at the top
                SearchBar(text: $searchQuery)
                    .padding(.horizontal)

                if filteredCustomers.isEmpty {
                    VStack {
                        Spacer()
                        Text("No customers available. Tap + to add a new customer.")
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding()
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(filteredCustomers) { customer in
                            NavigationLink(destination: CustomerDetailView(viewModel: viewModel, customer: customer)) {
                                Text(customer.name)
                            }
                        }
                        .onDelete { indexSet in
                            if let index = indexSet.first {
                                customerToDelete = filteredCustomers[index]
                                showingDeleteAlert = true
                            }
                        }
                    }
                }
            }
            .navigationTitle("Customers")
            .navigationBarItems(trailing: Button(action: {
                showingAddCustomerForm = true
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title)
            })
            .sheet(isPresented: $showingAddCustomerForm) {
                AddCustomerView(viewModel: viewModel, isPresented: $showingAddCustomerForm)
            }
            .alert(isPresented: $showingDeleteAlert) {
                Alert(
                    title: Text("Delete Customer"),
                    message: Text("Are you sure you want to delete this customer?"),
                    primaryButton: .destructive(Text("Delete")) {
                        if let customer = customerToDelete, let index = viewModel.customers.firstIndex(of: customer) {
                            viewModel.deleteCustomer(at: IndexSet(integer: index))
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }

    private var filteredCustomers: [Customer] {
        if searchQuery.isEmpty {
            return viewModel.customers
        } else {
            return viewModel.customers.filter { $0.name.contains(searchQuery) }
        }
    }
}









struct EditCustomerView: View {
    @ObservedObject var viewModel: CleanMasterViewModel
    @Environment(\.presentationMode) var presentationMode
    @State var customer: Customer
    @State private var customerName: String
    @State private var contact: String
    @State private var address: String

    init(viewModel: CleanMasterViewModel, customer: Customer) {
        self.viewModel = viewModel
        _customer = State(initialValue: customer)
        _customerName = State(initialValue: customer.name)
        _contact = State(initialValue: customer.contact)
        _address = State(initialValue: customer.address)
    }

    var body: some View {
        NavigationView {
            Form {
                TextField("Customer Name", text: $customerName)
                TextField("Contact", text: $contact)
                TextField("Address", text: $address)
            }
            .navigationTitle("Edit Customer")
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }, trailing: Button("Save") {
                updateCustomer()
            })
        }
    }

    private func updateCustomer() {
        customer.name = customerName
        customer.contact = contact
        customer.address = address

        if let index = viewModel.customers.firstIndex(where: { $0.id == customer.id }) {
            viewModel.customers[index] = customer
            viewModel.saveCustomers()
            presentationMode.wrappedValue.dismiss()
        }
    }
}





// MARK: - Add Customer View
struct AddCustomerView: View {
    @ObservedObject var viewModel: CleanMasterViewModel
    @Binding var isPresented: Bool
    @State private var customerName = ""
    @State private var contact = ""
    @State private var address = ""

    var body: some View {
        NavigationView {
            Form {
                TextField("Customer Name", text: $customerName)
                TextField("Contact", text: $contact)
                TextField("Address", text: $address)
            }
            .navigationTitle("Add Customer")
            .navigationBarItems(leading: Button("Cancel") {
                isPresented = false
            }, trailing: Button("Save") {
                let newCustomer = Customer(name: customerName, contact: contact, address: address)
                viewModel.addCustomer(customer: newCustomer)
                isPresented = false
            })
        }
    }
}

// MARK: - Customer Detail View
struct CustomerDetailView: View {
    @ObservedObject var viewModel: CleanMasterViewModel
    @State private var showingEditCustomerForm = false
    var customer: Customer

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Section(header: Text("Customer Information")
                        .font(.headline)
                        .padding(.top)) {
                HStack {
                    Text("Name:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(customer.name)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                HStack {
                    Text("Contact:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(customer.contact)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                HStack {
                    Text("Address:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(customer.address)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)

            Section(header: Text("Orders")
                        .font(.headline)
                        .padding(.top)) {
                if viewModel.orders.filter { $0.customerId == customer.id }.isEmpty {
                    Text("No orders available")
                        .foregroundColor(.gray)
                } else {
                    ForEach(viewModel.orders.filter { $0.customerId == customer.id }) { order in
                        VStack(alignment: .leading) {
                            Text("Item: \(order.itemType)")
                            Text("Status: \(order.status)")
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.bottom, 4)
                    }
                }
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Customer Details")
        .navigationBarItems(trailing: Button("Edit") {
            showingEditCustomerForm = true
        })
        .sheet(isPresented: $showingEditCustomerForm) {
            EditCustomerView(viewModel: viewModel, customer: customer)
        }
    }
}



// MARK: - Order List View
struct OrderListView: View {
    @ObservedObject var viewModel: CleanMasterViewModel
    @State private var showingAddOrderForm = false
    @State private var showingDeleteAlert = false
    @State private var orderToDelete: Order?

    var body: some View {
        NavigationView {
            VStack {
                // Search bar or any other UI elements...

                if viewModel.orders.isEmpty {
                    Text("No orders available. Tap + to add a new order.")
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    List {
                        ForEach(viewModel.orders) { order in
                            NavigationLink(destination: OrderDetailView(viewModel: viewModel, order: order)) {
                                Text(order.itemType)
                            }
                        }
                        .onDelete { indexSet in
                            if let index = indexSet.first {
                                orderToDelete = viewModel.orders[index]
                                showingDeleteAlert = true
                            }
                        }
                    }
                }
            }
            .navigationTitle("Orders")
            .navigationBarItems(trailing: Button(action: {
                showingAddOrderForm = true
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title)
            })
            .sheet(isPresented: $showingAddOrderForm) {
                AddOrderView(viewModel: viewModel, isPresented: $showingAddOrderForm)
            }
            .alert(isPresented: $showingDeleteAlert) {
                Alert(
                    title: Text("Delete Order"),
                    message: Text("Are you sure you want to delete this order?"),
                    primaryButton: .destructive(Text("Delete")) {
                        if let order = orderToDelete, let index = viewModel.orders.firstIndex(of: order) {
                            viewModel.deleteOrder(at: IndexSet(integer: index))
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
}


struct OrderDetailView: View {
    @ObservedObject var viewModel: CleanMasterViewModel
    @State private var showingEditOrderForm = false
    var order: Order

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Section(header: Text("Order Information")
                        .font(.headline)
                        .padding(.top)) {
                HStack {
                    Text("Item Type:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(order.itemType)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                HStack {
                    Text("Quantity:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(order.quantity)")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                HStack {
                    Text("Service Type:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(order.serviceType)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                HStack {
                    Text("Status:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(order.status)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                HStack {
                    Text("Order Date:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(order.orderDate, formatter: dateFormatter)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)

            Spacer()
        }
        .padding()
        .navigationTitle("Order Details")
        .navigationBarItems(trailing: Button("Edit") {
            showingEditOrderForm = true
        })
        .sheet(isPresented: $showingEditOrderForm) {
            EditOrderView(viewModel: viewModel, isPresented: $showingEditOrderForm, order: order)
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }
}






// MARK: - Add Order View
struct AddOrderView: View {
    @ObservedObject var viewModel: CleanMasterViewModel
    @Binding var isPresented: Bool
    @State private var selectedCustomer: Customer?
    @State private var itemType = ""
    @State private var quantity = 1
    @State private var serviceType = "Dry Cleaning"
    @State private var status = "Pending"
    @State private var orderDate = Date()

    let serviceTypes = ["Dry Cleaning", "Laundry", "Alterations", "Pressing"]
    let statusOptions = ["Pending", "In Process", "Completed"]

    var body: some View {
        NavigationView {
            Form {
                Picker("Customer", selection: $selectedCustomer) {
                    ForEach(viewModel.customers, id: \.self) { customer in
                        Text(customer.name).tag(customer as Customer?)
                    }
                }

                TextField("Item Type", text: $itemType)
                Stepper("Quantity: \(quantity)", value: $quantity, in: 1...100)
                
                Picker("Service Type", selection: $serviceType) {
                    ForEach(serviceTypes, id: \.self) { type in
                        Text(type)
                    }
                }
                
                Picker("Status", selection: $status) {
                    ForEach(statusOptions, id: \.self) { status in
                        Text(status)
                    }
                }
                
                DatePicker("Order Date", selection: $orderDate, displayedComponents: .date)
            }
            .navigationTitle("Add Order")
            .navigationBarItems(leading: Button("Cancel") {
                isPresented = false
            }, trailing: Button("Save") {
                if let customer = selectedCustomer {
                    let newOrder = Order(customerId: customer.id, itemType: itemType, quantity: quantity, serviceType: serviceType, status: status, orderDate: orderDate)
                    viewModel.addOrder(order: newOrder)
                    isPresented = false
                } else {
                    viewModel.alertMessage = "Please select a customer"
                    viewModel.showAlert = true
                }
            })
            .alert(isPresented: $viewModel.showAlert) {
                Alert(title: Text("Message"), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
}



struct EditOrderView: View {
    @ObservedObject var viewModel: CleanMasterViewModel
    @Binding var isPresented: Bool
    @State var order: Order

    let serviceTypes = ["Dry Cleaning", "Laundry", "Alterations", "Pressing"]
    let statusOptions = ["Pending", "In Process", "Completed"]

    var body: some View {
        NavigationView {
            Form {
                Picker("Customer", selection: $order.customerId) {
                    ForEach(viewModel.customers, id: \.id) { customer in
                        Text(customer.name).tag(customer.id)
                    }
                }

                TextField("Item Type", text: $order.itemType)
                Stepper("Quantity: \(order.quantity)", value: $order.quantity, in: 1...100)
                
                Picker("Service Type", selection: $order.serviceType) {
                    ForEach(serviceTypes, id: \.self) { type in
                        Text(type)
                    }
                }
                
                Picker("Status", selection: $order.status) {
                    ForEach(statusOptions, id: \.self) { status in
                        Text(status)
                    }
                }
                
                DatePicker("Order Date", selection: $order.orderDate, displayedComponents: .date)
            }
            .navigationTitle("Edit Order")
            .navigationBarItems(leading: Button("Cancel") {
                isPresented = false
            }, trailing: Button("Save") {
                if let index = viewModel.orders.firstIndex(where: { $0.id == order.id }) {
                    viewModel.orders[index] = order
                    viewModel.saveOrders()
                    isPresented = false
                } else {
                    viewModel.alertMessage = "Order not found."
                    viewModel.showAlert = true
                }
            })
            .alert(isPresented: $viewModel.showAlert) {
                Alert(title: Text("Message"), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
}






// MARK: - Payment List View
struct PaymentListView: View {
    @ObservedObject var viewModel: CleanMasterViewModel
    @State private var showingAddPaymentForm = false
    @State private var showingDeleteAlert = false
    @State private var paymentToDelete: Payment?

    var body: some View {
        NavigationView {
            VStack {
                // Search bar or any other UI elements...

                if viewModel.payments.isEmpty {
                    Text("No payments available. Tap + to add a new payment.")
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    List {
                        ForEach(viewModel.payments) { payment in
                            NavigationLink(destination: PaymentDetailView(viewModel: viewModel, payment: payment)) {
                                Text("Payment of \(payment.amount, specifier: "%.2f") - \(payment.paymentStatus)")
                            }
                        }
                        .onDelete { indexSet in
                            if let index = indexSet.first {
                                paymentToDelete = viewModel.payments[index]
                                showingDeleteAlert = true
                            }
                        }
                    }
                }
            }
            .navigationTitle("Payments")
            .navigationBarItems(trailing: Button(action: {
                showingAddPaymentForm = true
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title)
            })
            .sheet(isPresented: $showingAddPaymentForm) {
                AddPaymentView(viewModel: viewModel, isPresented: $showingAddPaymentForm)
            }
            .alert(isPresented: $showingDeleteAlert) {
                Alert(
                    title: Text("Delete Payment"),
                    message: Text("Are you sure you want to delete this payment?"),
                    primaryButton: .destructive(Text("Delete")) {
                        if let payment = paymentToDelete, let index = viewModel.payments.firstIndex(of: payment) {
                            viewModel.deletePayment(at: IndexSet(integer: index))
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
}


struct PaymentDetailView: View {
    @ObservedObject var viewModel: CleanMasterViewModel
    @State private var showingEditPaymentForm = false
    var payment: Payment

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Section(header: Text("Payment Information")
                        .font(.headline)
                        .padding(.top)) {
                HStack {
                    Text("Amount:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(payment.amount, specifier: "%.2f")")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                HStack {
                    Text("Payment Date:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(payment.paymentDate, formatter: dateFormatter)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                HStack {
                    Text("Payment Status:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(payment.paymentStatus)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                HStack {
                    Text("Payment Method:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(payment.paymentMethod)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)

            Spacer()
        }
        .padding()
        .navigationTitle("Payment Details")
        .navigationBarItems(trailing: Button("Edit") {
            showingEditPaymentForm = true
        })
        .sheet(isPresented: $showingEditPaymentForm) {
            EditPaymentView(viewModel: viewModel, isPresented: $showingEditPaymentForm, payment: payment)
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }
}






struct EditPaymentView: View {
    @ObservedObject var viewModel: CleanMasterViewModel
    @Binding var isPresented: Bool
    @State var payment: Payment

    let paymentStatuses = ["Paid", "Unpaid"]
    let paymentMethods = ["Cash", "Card", "Online"]

    var body: some View {
        NavigationView {
            Form {
                Picker("Order", selection: $payment.orderId) {
                    ForEach(viewModel.orders, id: \.id) { order in
                        Text(order.itemType).tag(order.id)
                    }
                }

                TextField("Amount", value: $payment.amount, formatter: NumberFormatter())
                DatePicker("Payment Date", selection: $payment.paymentDate, displayedComponents: .date)
                
                Picker("Payment Status", selection: $payment.paymentStatus) {
                    ForEach(paymentStatuses, id: \.self) { status in
                        Text(status)
                    }
                }

                Picker("Payment Method", selection: $payment.paymentMethod) {
                    ForEach(paymentMethods, id: \.self) { method in
                        Text(method)
                    }
                }
            }
            .navigationTitle("Edit Payment")
            .navigationBarItems(leading: Button("Cancel") {
                isPresented = false
            }, trailing: Button("Save") {
                if let index = viewModel.payments.firstIndex(where: { $0.id == payment.id }) {
                    viewModel.payments[index] = payment
                    viewModel.savePayments()
                    isPresented = false
                } else {
                    viewModel.alertMessage = "Payment not found."
                    viewModel.showAlert = true
                }
            })
            .alert(isPresented: $viewModel.showAlert) {
                Alert(title: Text("Message"), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
}



// MARK: - Add Payment View
struct AddPaymentView: View {
    @ObservedObject var viewModel: CleanMasterViewModel
    @Binding var isPresented: Bool
    @State private var selectedOrder: Order?
    @State private var amount = 0.0
    @State private var paymentDate = Date()
    @State private var paymentStatus = "Unpaid"
    @State private var paymentMethod = "Cash"

    let paymentMethods = ["Cash", "Card", "Online Payment"]

    var body: some View {
        NavigationView {
            Form {
                Picker("Order", selection: $selectedOrder) {
                    ForEach(viewModel.orders, id: \.self) { order in
                        Text(order.itemType).tag(order as Order?)
                    }
                }

                TextField("Amount", value: $amount, formatter: NumberFormatter())
                DatePicker("Payment Date", selection: $paymentDate, displayedComponents: .date)
                
                Picker("Payment Method", selection: $paymentMethod) {
                    ForEach(paymentMethods, id: \.self) { method in
                        Text(method)
                    }
                }
                
                TextField("Payment Status", text: $paymentStatus)
            }
            .navigationTitle("Add Payment")
            .navigationBarItems(leading: Button("Cancel") {
                isPresented = false
            }, trailing: Button("Save") {
                if let order = selectedOrder {
                    let newPayment = Payment(orderId: order.id, amount: amount, paymentDate: paymentDate, paymentStatus: paymentStatus, paymentMethod: paymentMethod)
                    viewModel.addPayment(payment: newPayment)
                    isPresented = false
                } else {
                    viewModel.alertMessage = "Please select an order"
                    viewModel.showAlert = true
                }
            })
            .alert(isPresented: $viewModel.showAlert) {
                Alert(title: Text("Message"), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
}


// MARK: - Main Tab View
struct MainTabView: View {
    @StateObject var viewModel = CleanMasterViewModel()

    var body: some View {
        TabView {
            CustomerListView(viewModel: viewModel)
                .tabItem {
                    Label("Customers", systemImage: "person.3.fill")
                }

            OrderListView(viewModel: viewModel)
                .tabItem {
                    Label("Orders", systemImage: "doc.text.fill")
                }

            PaymentListView(viewModel: viewModel)
                .tabItem {
                    Label("Payments", systemImage: "creditcard.fill")
                }
        }
    }
}

// MARK: - Main App
@main
struct CleanMasterApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}
