//
//  ViewController.swift
//  Project5
//
//  Created by Hassan Sohail Dar on 17/8/2022.
//

import UIKit

class ViewController: UITableViewController {
    var allWords = [String]()
    var usedWords = [String]()
    
    var savedWordsGuessed = [String]()
    var selectedWord = ""
    
    fileprivate func loadUserDefaults() -> Bool {
        // if the word and guessed words already exists. Lets load the game where we left it off.
        let defaults = UserDefaults.standard
        
        if let savedWordsList = defaults.object(forKey: "savedWordsGuessed") as? Data {
            if let theWord = defaults.object(forKey: "selectedWord") as? Data {
                let jsonDecoder = JSONDecoder()
                
                do {
                    savedWordsGuessed = try jsonDecoder.decode([String].self, from: savedWordsList)
                    selectedWord = try jsonDecoder.decode(String.self, from: theWord )
                    return true
                } catch {
                    print("failed to save words")
                }
                
            }
        }
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(promptForAnswer))
        //adding a left bar button item that will restart the game
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(startGame))
        
        
        if let startWordsURL = Bundle.main.url(forResource: "start", withExtension: "txt") {
            if let startWords = try? String(contentsOf: startWordsURL) {
                allWords = startWords.components(separatedBy: "\n")
            }
        }
        
        if allWords.isEmpty {
            allWords = ["silkworm"]
        }
        
        if  loadUserDefaults() {
            title = selectedWord
            usedWords = savedWordsGuessed
            tableView.reloadData()
            return
        }
        
        startGame()
    }
    
    @objc func startGame() {
        
        title = allWords.randomElement()
        usedWords.removeAll(keepingCapacity: true)
        removeUserDefaults()
        tableView.reloadData()
        
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usedWords.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Word", for: indexPath)
        cell.textLabel?.text = usedWords[indexPath.row]
        return cell
    }
    
    @objc func promptForAnswer() {
        let ac = UIAlertController(title: "Enter answer", message: nil, preferredStyle: .alert)
        ac.addTextField()
        
        let submitAction = UIAlertAction(title: "Submit", style: .default) { [weak self, weak ac] _ in
            guard let answer = ac?.textFields?[0].text?.lowercased() else { return }
            self?.submit(answer: answer)
        }
        
        ac.addAction(submitAction)
        present(ac, animated: true)
    }
    func isPossible(word: String) -> Bool {
        guard var tempWord = title?.lowercased() else { return false }
        
        for letter in word {
            if let position = tempWord.firstIndex(of: letter) {
                tempWord.remove(at: position)
            } else {
                return false
            }
        }
        
        return true
    }
    
    func isOriginal(word: String) -> Bool {
        if(title == word) {
            
            showErrorMessage(title: "Same word", message: "You cannot use the original word to gain points.")
            
            return false
        }
        return !usedWords.contains(word)
    }
    
    func isReal(word: String) -> Bool {
        let checker = UITextChecker()
        if word.count < 3 {
            return false
        }
        let range = NSRange(location: 0, length: word.utf16.count)
        let misspelledRange = checker.rangeOfMisspelledWord(in: word, range: range, startingAt: 0, wrap: false, language: "en")
        
        return misspelledRange.location == NSNotFound
    }
    
    func submit(answer: String) {
        let lowerAnswer = answer.lowercased()
        
        let errorTitle: String
        let errorMessage: String
        
        if isPossible(word: lowerAnswer) {
            if isOriginal(word: lowerAnswer) {
                if isReal(word: lowerAnswer) {
                    usedWords.insert(answer, at: 0)
                    
                    //save in UserDefaults
                    saveInUserDefaults()
                    
                    let indexPath = IndexPath(row: 0, section: 0)
                    tableView.insertRows(at: [indexPath], with: .automatic)
                    
                    return
                } else {
                    errorTitle = "Word not recognised"
                    errorMessage = "You can't just make them up, you know!"
                }
            } else {
                errorTitle = "Word used already"
                errorMessage = "Be more original!"
            }
        } else {
            guard let title = title?.lowercased() else { return }
            errorTitle = "Word not possible"
            errorMessage = "You can't spell that word from \(title)"
        }
        
        showErrorMessage(title: errorTitle, message: errorMessage)
    }
    
    func showErrorMessage(title: String, message: String) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
    
    func removeUserDefaults() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "savedWordsGuessed")
        defaults.removeObject(forKey: "selectedWord")
    }
    
    func saveInUserDefaults() {
        let defaults = UserDefaults.standard
        let jsonEncoder = JSONEncoder()
        if let savedTitle = try? jsonEncoder.encode(title) {
            if let savedGuesses = try? jsonEncoder.encode(usedWords) {
                defaults.set(savedTitle, forKey: "selectedWord")
                defaults.set(savedGuesses, forKey: "savedWordsGuessed")
                
            }
        } else {
            print("Failed to save in User Defaults.")
        }
        
    }
}

