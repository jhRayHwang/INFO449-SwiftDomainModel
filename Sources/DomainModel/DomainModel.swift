public struct DomainModel {
    var text = "Hello, World!"
    // Leave this here; this value is also tested in the tests,
    // and serves to make sure that everything is working correctly
    // in the testing harness and framework.
}


public struct Money {
    public var amount: Int
    public var currency: String

    private static let validCurrencies: [String] = ["USD", "GBP", "EUR", "CAN"]
    // Exchange rates are defined relative to USD.
    // For example, 1 USD = 0.5 GBP, 1 USD = 1.5 EUR, and 1 USD = 1.25 CAN.
    private static let exchangeRates: [String: Double] = [
        "USD": 1.0,
        "GBP": 0.5,
        "EUR": 1.5,
        "CAN": 1.25
    ]
    
    public init(amount: Int, currency: String) {
        guard Money.validCurrencies.contains(currency) else {
            fatalError("Invalid currency: \(currency)")
        }
        self.amount = amount
        self.currency = currency
    }
    
    public func convert(_ to: String) -> Money {
        guard Money.validCurrencies.contains(to) else {
            fatalError("Invalid target currency: \(to)")
        }
        if self.currency == to { return self }
        guard let fromRate = Money.exchangeRates[self.currency],
              let toRate = Money.exchangeRates[to] else {
            fatalError("Missing exchange rate for conversion.")
        }
        // Normalize through USD.
        let amountInUSD = Double(self.amount) / fromRate
        let newAmount = Int((amountInUSD * toRate).rounded())
        return Money(amount: newAmount, currency: to)
    }
    
    // UPDATED: When adding two Money values with different currencies,
    // convert self into the currency of the parameter (other) and then add.
    public func add(_ other: Money) -> Money {
        let convertedSelf = self.convert(other.currency)
        return Money(amount: convertedSelf.amount + other.amount, currency: other.currency)
    }
    
    // Similarly, for subtraction convert self into the currency of 'other'.
    public func subtract(_ other: Money) -> Money {
        let convertedSelf = self.convert(other.currency)
        return Money(amount: convertedSelf.amount - other.amount, currency: other.currency)
    }
}


public class Job {
    
    public enum JobType {
        case Hourly(Double)   // Hourly wage (per hour)
        case Salary(Int)      // Yearly salary amount
    }
    
    public var title: String
    public var type: JobType
    
    public init(title: String, type: JobType) {
        self.title = title
        self.type = type
    }
    
    // Calculates the income.
    // For Hourly jobs, the provided hours (defaulting to 2000 when not specified) are multiplied by the hourly wage.
    // For Salary jobs, any passed parameter is ignored.
    public func calculateIncome(_ hours: Int = 2000) -> Int {
        switch type {
        case .Hourly(let wage):
            return Int((wage * Double(hours)).rounded())
        case .Salary(let salary):
            return salary
        }
    }
    
    // Raises the pay by a fixed amount.
    public func raise(byAmount amount: Double) {
        switch type {
        case .Hourly(let wage):
            self.type = .Hourly(wage + amount)
        case .Salary(let salary):
            self.type = .Salary(salary + Int(amount))
        }
    }
    
    // Raises the pay by a percentage.
    public func raise(byPercent percent: Double) {
        switch type {
        case .Hourly(let wage):
            self.type = .Hourly(wage * (1 + percent))
        case .Salary(let salary):
            self.type = .Salary(Int((Double(salary) * (1 + percent)).rounded()))
        }
    }
}

extension Job: CustomStringConvertible {
    public var description: String {
        switch type {
        case .Hourly(let wage):
            return "Hourly(\(wage))"
        case .Salary(let salary):
            return "Salary(\(salary))"
        }
    }
}


public class Person {
    public var firstName: String
    public var lastName: String
    public var age: Int
    
    // Use private storage to enforce the age restrictions on assignment.
    private var _job: Job? = nil
    public var job: Job? {
        get { return _job }
        set {
            // Only assign a job if the person is at least 16 years old.
            if age >= 16 {
                _job = newValue
            } else {
                _job = nil
            }
        }
    }
    
    private var _spouse: Person? = nil
    public var spouse: Person? {
        get { return _spouse }
        set {
            // Only allow marriage if both persons are at least 18 years old.
            if let newSpouse = newValue, age >= 18, newSpouse.age >= 18 {
                _spouse = newSpouse
            } else {
                _spouse = nil
            }
        }
    }
    
    public init(firstName: String, lastName: String, age: Int) {
        self.firstName = firstName
        self.lastName = lastName
        self.age = age
    }
    
    // Returns a human-readable description of the Person.
    // Example: "[Person: firstName: Ted lastName: Neward age: 45 job: Salary(1000) spouse: Charlotte]"
    public func toString() -> String {
        let jobStr = job != nil ? "\(job!)" : "nil"
        let spouseStr = spouse != nil ? spouse!.firstName : "nil"
        return "[Person: firstName:\(firstName) lastName:\(lastName) age:\(age) job:\(jobStr) spouse:\(spouseStr)]"
    }
}


public class Family {
    public var members: [Person] = []
    
    public init(spouse1: Person, spouse2: Person) {
        if spouse1.spouse != nil || spouse2.spouse != nil {
            fatalError("One or both persons are already married.")
        }
        spouse1.spouse = spouse2
        spouse2.spouse = spouse1
        members.append(contentsOf: [spouse1, spouse2])
    }
    
    public func haveChild(_ child: Person) -> Bool {
        guard members.count >= 2 else { return false }
        let spouse1 = members[0]
        let spouse2 = members[1]
        if spouse1.age >= 21 || spouse2.age >= 21 {
            members.append(child)
            return true
        }
        return false
    }
    
    public func householdIncome() -> Int {
        return members.reduce(0) { total, person in
            if let job = person.job {
                return total + job.calculateIncome()
            }
            return total
        }
    }
}
