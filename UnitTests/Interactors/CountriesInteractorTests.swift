//
//  CountriesInteractorTests.swift
//  UnitTests
//
//  Created by Alexey Naumov on 31.10.2019.
//  Copyright © 2019 Alexey Naumov. All rights reserved.
//

import XCTest
import SwiftUI
import Combine
@testable import CountriesSwiftUI

final class CountriesInteractorTests: XCTestCase {

    let appState = CurrentValueSubject<AppState, Never>(AppState())
    var mockedRepository: MockedCountriesWebRepository!
    var sut: RealCountriesInteractor!
    var subscriptions = Set<AnyCancellable>()
    
    override func setUp() {
        appState.value = AppState()
        mockedRepository = MockedCountriesWebRepository()
        sut = RealCountriesInteractor(webRepository: mockedRepository, appState: appState)
        subscriptions = Set<AnyCancellable>()
    }
    
    // MARK: - loadCountries
    
    func test_loadCountries_notRequested_to_loaded() {
        let countries = Country.mockedData
        mockedRepository.countriesResponse = .success(countries)
        mockedRepository.actions = .init(expected: [
            .loadCountries
        ])
        let updates = recordAppStateUserDataUpdates()
        sut.loadCountries()
        let exp = XCTestExpectation(description: "Completion")
        updates.sink { updates in
            XCTAssertEqual(updates, [
                AppState.UserData(countries: .notRequested),
                AppState.UserData(countries: .isLoading(last: nil, cancelBag: CancelBag())),
                AppState.UserData(countries: .loaded(countries))
            ])
            self.mockedRepository.verify()
            exp.fulfill()
        }.store(in: &subscriptions)
        wait(for: [exp], timeout: 2)
    }
    
    func test_loadCountries_loaded_to_loaded() {
        let initialCountries = Country.mockedData
        let finalCountries = [initialCountries[0], initialCountries[1]]
        appState[\.userData.countries] = .loaded(initialCountries)
        mockedRepository.countriesResponse = .success(finalCountries)
        mockedRepository.actions = .init(expected: [
            .loadCountries
        ])
        let updates = recordAppStateUserDataUpdates()
        sut.loadCountries()
        let exp = XCTestExpectation(description: "Completion")
        updates.sink { updates in
            XCTAssertEqual(updates, [
                AppState.UserData(countries: .loaded(initialCountries)),
                AppState.UserData(countries: .isLoading(last: initialCountries,
                                                        cancelBag: CancelBag())),
                AppState.UserData(countries: .loaded(finalCountries))
            ])
            self.mockedRepository.verify()
            exp.fulfill()
        }.store(in: &subscriptions)
        wait(for: [exp], timeout: 2)
    }
    
    func test_loadCountries_notRequested_to_failed() {
        let error = NSError.test
        mockedRepository.countriesResponse = .failure(error)
        mockedRepository.actions = .init(expected: [
            .loadCountries
        ])
        let updates = recordAppStateUserDataUpdates()
        sut.loadCountries()
        let exp = XCTestExpectation(description: "Completion")
        updates.sink { updates in
            XCTAssertEqual(updates, [
                AppState.UserData(countries: .notRequested),
                AppState.UserData(countries: .isLoading(last: nil, cancelBag: CancelBag())),
                AppState.UserData(countries: .failed(error))
            ])
            self.mockedRepository.verify()
            exp.fulfill()
        }.store(in: &subscriptions)
        wait(for: [exp], timeout: 2)
    }
    
    // MARK: - loadCountryDetails
    
    func test_loadCountryDetails_countries_notRequested() {
        let country = Country.mockedData[0]
        let data = countryDetails(neighbors: [])
        appState[\.userData.countries] = .notRequested
        mockedRepository.detailsResponse = .success(data.intermediate)
        mockedRepository.actions = .init(expected: [
            .loadCountryDetails(country)
        ])
        let details = BindingWithPublisher(value: Loadable<Country.Details>.notRequested)
        sut.load(countryDetails: details.binding, country: country)
        let exp = XCTestExpectation(description: "Completion")
        details.updatesRecorder.sink { updates in
            XCTAssertEqual(updates, [
                .notRequested,
                .isLoading(last: nil, cancelBag: CancelBag()),
                .loaded(data.details)
            ])
            self.mockedRepository.verify()
            exp.fulfill()
        }.store(in: &subscriptions)
        wait(for: [exp], timeout: 2)
    }
    
    func test_loadCountryDetails_countries_loaded() {
        let countries = Country.mockedData
        let country = countries[0]
        let data = countryDetails(neighbors: countries)
        appState[\.userData.countries] = .loaded(countries)
        mockedRepository.detailsResponse = .success(data.intermediate)
        mockedRepository.actions = .init(expected: [
            .loadCountryDetails(country)
        ])
        let details = BindingWithPublisher(value: Loadable<Country.Details>.notRequested)
        sut.load(countryDetails: details.binding, country: country)
        let exp = XCTestExpectation(description: "Completion")
        details.updatesRecorder.sink { updates in
            XCTAssertEqual(updates, [
                .notRequested,
                .isLoading(last: nil, cancelBag: CancelBag()),
                .loaded(data.details)
            ])
            self.mockedRepository.verify()
            exp.fulfill()
        }.store(in: &subscriptions)
        wait(for: [exp], timeout: 2)
    }
    
    func test_loadCountryDetails_countries_failed() {
        let countries = Country.mockedData
        let country = countries[0]
        let error = NSError.test
        let data = countryDetails(neighbors: countries)
        appState[\.userData.countries] = .failed(error)
        mockedRepository.detailsResponse = .success(data.intermediate)
        mockedRepository.actions = .init(expected: [
            .loadCountryDetails(country)
        ])
        let details = BindingWithPublisher(value: Loadable<Country.Details>.notRequested)
        sut.load(countryDetails: details.binding, country: country)
        let exp = XCTestExpectation(description: "Completion")
        details.updatesRecorder.sink { updates in
            XCTAssertEqual(updates, [
                .notRequested,
                .isLoading(last: nil, cancelBag: CancelBag()),
                .failed(error)
            ])
            self.mockedRepository.verify()
            exp.fulfill()
        }.store(in: &subscriptions)
        wait(for: [exp], timeout: 2)
    }
    
    func test_loadCountryDetails_refresh() {
        let countries = Country.mockedData
        let country = countries[0]
        let data = countryDetails(neighbors: countries)
        appState[\.userData.countries] = .loaded(countries)
        mockedRepository.detailsResponse = .success(data.intermediate)
        mockedRepository.actions = .init(expected: [
            .loadCountryDetails(country)
        ])
        let details = BindingWithPublisher(value: Loadable<Country.Details>.loaded(data.details))
        sut.load(countryDetails: details.binding, country: country)
        let exp = XCTestExpectation(description: "Completion")
        details.updatesRecorder.sink { updates in
            XCTAssertEqual(updates, [
                .loaded(data.details),
                .isLoading(last: data.details, cancelBag: CancelBag()),
                .loaded(data.details)
            ])
            self.mockedRepository.verify()
            exp.fulfill()
        }.store(in: &subscriptions)
        wait(for: [exp], timeout: 2)
    }
    
    func test_loadCountryDetails_failure() {
        let error = NSError.test
        let countries = Country.mockedData
        let country = countries[0]
        appState[\.userData.countries] = .loaded(countries)
        mockedRepository.detailsResponse = .failure(error)
        mockedRepository.actions = .init(expected: [
            .loadCountryDetails(country)
        ])
        let details = BindingWithPublisher(value: Loadable<Country.Details>.notRequested)
        sut.load(countryDetails: details.binding, country: country)
        let exp = XCTestExpectation(description: "Completion")
        details.updatesRecorder.sink { updates in
            XCTAssertEqual(updates, [
                .notRequested,
                .isLoading(last: nil, cancelBag: CancelBag()),
                .failed(error)
            ])
            self.mockedRepository.verify()
            exp.fulfill()
        }.store(in: &subscriptions)
        wait(for: [exp], timeout: 2)
    }
    
    func test_stubInteractor() {
        let sut = StubCountriesInteractor()
        sut.loadCountries()
        let details = BindingWithPublisher(value: Loadable<Country.Details>.notRequested)
        sut.load(countryDetails: details.binding, country: Country.mockedData[0])
    }
    
    // MARK: - Helper
    
    private func recordAppStateUserDataUpdates(for timeInterval: TimeInterval = 0.5)
        -> AnyPublisher<[AppState.UserData], Never> {
        return Future<[AppState.UserData], Never> { (completion) in
            var updates = [AppState.UserData]()
            self.appState.map(\.userData)
                .sink { updates.append($0 )}
                .store(in: &self.subscriptions)
            DispatchQueue.main.asyncAfter(deadline: .now() + timeInterval) {
                completion(.success(updates))
            }
        }.eraseToAnyPublisher()
    }
    
    private func countryDetails(neighbors: [Country])
        -> (intermediate: Country.Details.Intermediate, details: Country.Details) {
        let intermediate = Country.Details.Intermediate(
            capital: "London",
            currencies: [Country.Currency(code: "12", symbol: "$", name: "US dollar")],
            borders: neighbors.map { $0.alpha3Code })
        let details = Country.Details(capital: intermediate.capital,
                                      currencies: intermediate.currencies,
                                      neighbors: neighbors)
        return (intermediate, details)
    }
}
