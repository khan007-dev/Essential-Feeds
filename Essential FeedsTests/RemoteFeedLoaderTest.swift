//
//  RemoteFeedLoaderTest.swift
//  Essential FeedsTests
//
//  Created by Khan on 07.03.2024.
//

import Foundation
import XCTest
@testable import Essential_Feeds



class RemoteFeedLoaderTest: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        
        let (_, client) = makeSUT()
        
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    
    
    func test_load_requestsDataFromURL() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        
        sut.load {_ in }
        
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadTwice_requestsDataFromURLTwice() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        
        sut.load { _ in }
        sut.load { _ in }
        
        
        XCTAssertEqual(client.requestedURLs, [url, url])
        
    }
    
    func test_load_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()
        

        expect(sut, toCompleteWithError: .failure(.connectivity), when: {
            let clientError = NSError(domain: "Test", code: 0)
            client.complete(with: clientError)
        })

    }
    
    func test_load_deliversErrorOnNon200HTTPPresonse() {
        let (sut, client) = makeSUT()
        
        
        let samples = [199, 201, 300, 400, 500]
        samples.enumerated().forEach { index, code in
            
            expect(sut, toCompleteWithError: .invalidData, when: {
                client.complete(withStatusCode: code, at: index)
            })
            
            
        }
        
        
    }
    
    func test_load_deliversErrorOn200HTTPResponseWigthInvalidJSON() {
        let (sut,client) = makeSUT()
        
        expect(sut, toCompleteWithError: .invalidData, when: {
            let invalidJSON = Data(bytes: "invalid json".utf8)
            client.complete(withStatusCode: 200, data: invalidJSON)
        })
        
        
    }
    
    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJSONList() {
        
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: .success([]), when: {
            
            let emptyListJSON = Data(bytes: "{\"items\": []}".utf8)
            client.complete(withStatusCode: 200, data: emptyListJSON)
            XCTAssertEqual(captureResult, [.success([])])
        })
       
        
    }
    
    func test_load_deliversNoItemsOn200HTTPREsponseWithEmptyJSONList() {
        
        let (sut, client) = makeSUT()
        var capturedResult = [RemoteFeedLoader.Result]()
        sut.load(completion:  { capturedResult.append($0)}
        
        let emptyListJSON = Data(bytes: "{\"item\": []}".utf8)
            client.complete(withStatusCode: 200, data: emptyListJSON)
                 
                 XCTAssertEqual(capturedResult, [.success([])])

    }
    
                 
      func test_load_deliversItemOn200HTPResponseWithJSONItems() {
            
            let (sut, client) = makeSUT()
            let item1 = FeedItem(id: UUID(), description: nil, location: nil, imageURL: URL(string: "htpp://a-url.com")!)
            
            
            let item1JSON = [
                "id": item1.id.uuidString,
                "image": item1.imageURL.absoluteString
            ]
            
            let item2 = FeedItem(id: UUID(), description: "a desription", location: "a description", imageURL: URL(string: "http: //another-url.com")!)
            
            let item2JSON = [
                "id": item2.id.uuidString,
                "description": item2.description,
                "location": item2.location,
                "image": item2.imageURL.absoluteString
            ]
            
            let itemJSON = [
            
                "items": [item1JSON, item2JSON]
            ]
            
        expect (sut, toCompleteWith: .success([item1, item2]),
        when: {
            let json = try! JSONSerialization.data(withJSONObject: itemJSON)
            client.complete(withStatusCode: 200, data: json)
        })
        }
    
    
    // MARK: - Helper
    
    private func makeSUT (url: URL = URL(string: "https://a-url.com")!)  ->
    (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut =  RemoteFeedLoader(url: url, client: client)
        return (sut, client)
        
    }
    
    private func expect(_ sut: RemoteFeedLoader,
                        toCompleteWithErrorresult: RemoteFeedLoader.Result, when action:() -> Void, file: StaticString = #file, line: UInt = #line) {
        var capturedErrors = [RemoteFeedLoader.Result]()
        sut.load { capturedErrors.append($0) }
        
        action()
        
        XCTAssertEqual(capturedErrors, [result], file: file, line: line)
    }
    
    
    private class HTTPClientSpy: HTTPClient {
        private var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()
        
        var requestedURLs: [URL] {
            return messages.map { $0.url}
        }
        
        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
           
            messages.append((url, completion))
         
       }
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }
        func complete(withStatusCode code: Int, data: Data = Data(), at index: Int = 0) {
            let response = HTTPURLResponse(url: requestedURLs[index],
            statusCode: code,
            httpVersion: nil,
            headerFields: nil)!
            messages[index].completion (.success(response))
        }
      
   }
  
}
