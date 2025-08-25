import Foundation
import FirebaseFirestore

final class GarageService {
    static let shared = GarageService()
    private let db = Firestore.firestore()
    private init() {}

    func observeGarages(onChange: @escaping ([Garage]) -> Void) {
        db.collection("garages").addSnapshotListener { snapshot, _ in
            let garages = snapshot?.documents.compactMap { Garage(from: $0) } ?? []
            onChange(garages)
        }
    }

    func checkIn(to garage: Garage, completion: @escaping (Result<Void, Error>) -> Void) {
        let ref = db.collection("garages").document(garage.id)

        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let document: DocumentSnapshot
            do {
                document = try transaction.getDocument(ref)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            guard let data = document.data(),
                  let capacity = data["Capacity"] as? Int,
                  let currentCount = data["Currentcount"] as? Int else {
                return nil
            }

            if currentCount < capacity {
                transaction.updateData(["Currentcount": currentCount + 1], forDocument: ref)
            } else {
                errorPointer?.pointee = NSError(
                    domain: "GarageService",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Garage is full"]
                )
            }
            return nil
        }) { (_, error) in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func checkOut(from garage: Garage, completion: @escaping (Result<Void, Error>) -> Void) {
        let ref = db.collection("garages").document(garage.id)

        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let document: DocumentSnapshot
            do {
                document = try transaction.getDocument(ref)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            guard let data = document.data(),
                  let currentCount = data["Currentcount"] as? Int else {
                return nil
            }

            let newCount = max(currentCount - 1, 0)
            transaction.updateData(["Currentcount": newCount], forDocument: ref)
            return nil
        }) { (_, error) in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
