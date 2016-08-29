//: Playground - noun: a place where people can play

import UIKit

class AStar {
    struct Position: Equatable {
        static let MaxY = 1000
        
        let x: Int
        let y: Int
        
        var index: Int {
            return x + y * Position.MaxY
        }
        
        func add(x: Int = 0, y: Int = 0) -> Position {
            return Position(x: self.x + x, y: self.y + y)
        }
    }
    
    class MapData {
        enum Pattern {
            case 🌊, 🗻, 🌲
            
            var walkable: Bool {
                switch self {
                case .🌊, .🗻: return false
                case .🌲: return true
                }
            }
        }
        
        let rawValue: [[Pattern]]
        
        init(rawValue: [[Pattern]]) {
            self.rawValue = rawValue
        }
        
        func isInRange(position: Position) -> Bool {
            return rawValue.count > position.y && rawValue[position.y].count > position.x
        }
        
        subscript(index: Position) -> Pattern {
            return rawValue[index.y][index.x]
        }
    }
    
    private class Node {
        enum Status { case None, Open, Closed }
        
        var position: Position
        var status: Status
        var cost: Int
        var heuristic: Int
        var parent: Node?
        
        var score: Int { return cost + heuristic }
        
        init(position: Position, end: Position, heuristicCost: (_ start: Position, _ end: Position) -> Int) {
            self.position = position
            self.status = .None
            self.cost = 0
            self.heuristic = heuristicCost(position, end)
            self.parent = nil
        }
        
        func open(cost: Int, parent: Node?) -> Bool {
            guard case .None = status else { return false }
            status = .Open
            self.cost = cost
            self.parent = parent
            return true
        }
        
        func path() -> [Position] {
            var list = [position]
            var node = self
            while true {
                guard let parent = node.parent else { break }
                list.append(parent.position)
                node = parent
            }
            
            return list
        }
    }
    
    
    let mapData: MapData
    let start: Position
    let end: Position
    
    private var openList = [Node]()
    private var cache = [Int: Node]()
    
    init(mapData: MapData, start: Position, end: Position) {
        self.mapData = mapData
        self.start = start
        self.end = end
    }
    
    func find() -> [Position]? {
        guard mapData.rawValue.count < Position.MaxY else {
            print("データが大きすぎる")
            return nil
        }
        
        guard start != end else {
            print("スタートとゴールが同じ")
            return nil
        }
        
        guard mapData.isInRange(position: start) && mapData.isInRange(position: end) else {
            print("マップ上に存在しない位置")
            return nil
        }
        
        guard mapData[start].walkable && mapData[end].walkable else {
            print("進入不可の位置")
            return nil
        }
        
        guard var node = openNode(position: start, cost: 0, parent: nil) else { return nil }
        openList.append(node)
        
        while true {
            openList.remove(at: openList.index(where: { $0.position == node.position })!)
            openAround(parent: node)
            guard let next = minScoreNode() else { return [] }
            node = next
            if node.position == end {
                return node.path()
            }
        }
    }
    
    static private func calcHeuristicCost(start: Position, end: Position) -> Int {
        return abs(start.x - end.x) + abs(start.y - end.y)
    }
    
    private func nodeAtPosition(position: Position) -> Node {
        return cache[position.index]
            ?? Node(position: position, end: end, heuristicCost: AStar.calcHeuristicCost)
    }
    
    private func openNode(position: Position, cost: Int, parent: Node?) -> Node? {
        // マップ外かどうか
        guard mapData.isInRange(position: position) else { return nil }
        // 進入可能かどうか
        guard mapData[position].walkable else { return nil }
        
        let n = nodeAtPosition(position: position)
        guard n.open(cost: cost, parent: parent) else { return nil }
        
        openList.append(n)
        return n
    }
    
    private func openAround(parent: Node) {
        let cost = parent.cost + 1
        openNode(position: parent.position.add(x: -1), cost: cost, parent: parent)
        openNode(position: parent.position.add(y: -1), cost: cost, parent: parent)
        openNode(position: parent.position.add(x: 1), cost: cost, parent: parent)
        openNode(position: parent.position.add(y: 1), cost: cost, parent: parent)
    }
    
    private func minScoreNode() -> Node? {
        var minScore = Int.max
        var minCost = Int.max
        
        var result: Node? = nil
        for node in openList {
            let score = node.score
            guard score <= minScore else { continue }
            guard score < minScore || node.cost < minCost else { continue }
            
            minScore = score
            minCost = node.cost
            result = node
        }
        return result
    }
    
    func dump(path: [Position]) {
        for pos in path.reversed() {
            var text = "\n==================\n"
            for (y, line) in mapData.rawValue.enumerated() {
                for (x, type) in line.enumerated() {
                    switch Position(x: x, y: y) {
                    case start: text += "🚩"
                    case pos: text += "🏃"
                    case end: text += "🏁"
                    default:  text += String(describing: type)
                    }
                }
                text += "\n"
            }
            text += "\n==================\n"
            
            print(text)
        }
    }
}

func == (left: AStar.Position, right: AStar.Position) -> Bool {
    return left.x == right.x && left.y == right.y
}

var mapData = AStar.MapData(rawValue: [
    [.🌊, .🌲, .🌲, .🌲, .🌲, .🌲, .🌲, .🌲],
    [.🌊, .🌲, .🌲, .🌲, .🌲, .🌲, .🌲, .🌲],
    [.🌲, .🌲, .🌲, .🌲, .🗻, .🌲, .🌲, .🌲],
    [.🌲, .🌲, .🗻, .🗻, .🗻, .🗻, .🌲, .🌲],
    [.🌲, .🌲, .🗻, .🗻, .🌲, .🌲, .🌊, .🌊],
    [.🌲, .🌲, .🌲, .🌲, .🌲, .🌲, .🌲, .🌊],
    [.🌊, .🌲, .🌲, .🌲, .🌲, .🌲, .🌲, .🌲],
    [.🌊, .🌲, .🌲, .🌲, .🌲, .🌲, .🌲, .🌲]
])


let astar = AStar(mapData: mapData, start: AStar.Position(x: 1, y: 2), end: AStar.Position(x: 6, y: 6))
let list = astar.find()
astar.dump(path: list!)


