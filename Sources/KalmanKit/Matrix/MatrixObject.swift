//
//  MatrixObject.swift
//  KalmanKit
//
//  Created by El Mostafa El Ouatri on 09/05/25.
//

import Foundation
import Surge

class MatrixObject {
    // MARK: - Public properties

    /// Surge Matrix object
    var matrix: Matrix<Double>

    // MARK: - Private properties
    
    /// Number of Rows in Matrix
    private var rows: Int
    
    /// Number of Columns in Matrix
    private var columns: Int
    
    // MARK: - Initialization
    
    /// Initailization of matrix with specified numbers of rows and columns
    init(rows: Int, columns: Int) {
        self.rows = rows;
        self.columns = columns;
        self.matrix = Matrix<Double>(rows: self.rows, columns: self.columns, repeatedValue: 0.0)
    }
    
    // MARK: - MatrixObject functions
    
    /// identity Function
    /// ==========================
    /// For some dimension dim, return identity matrix object
    ///
    /// - parameters:
    ///   - dimension: dimension of desired identity matrix
    /// - returns: identity matrix object
    static func identity(dimension: Int) -> MatrixObject {
        let identityMatrix = MatrixObject(rows: dimension, columns: dimension)
        
        for row in 0..<dimension {
            for column in 0..<dimension {
                if row == column {
                    identityMatrix.matrix[row, column] = 1.0
                }
            }
        }
        
        return identityMatrix
    }
    
    /// add Function
    /// ===================
    /// Add double value on (i,j) position in matrix
    ///
    /// - parameters:
    ///   - row: row of matrix
    ///   - column: column of matrix
    ///   - value: double value to add in matrix
    public func add(row: Int, column: Int, value: Double) {
        if self.matrix.rows > row && self.matrix.columns > column {
            self.matrix[row, column] = value;
        } else {
            print("error")
        }
    }
    
    /// set Function
    /// ==================
    /// Set complete matrix
    ///
    /// - parameters:
    ///   - matrix: array of array of double values
    public func set(matrix:[[Double]]) {
        if self.matrix.rows > 0 {
            if (matrix.count == self.matrix.rows) && (matrix[0].count == self.matrix.columns) {
                self.matrix = Matrix<Double>(matrix)
            }
        }
    }
    
    /// get Function
    /// ===================
    /// Returns double value on specific position of matrix
    ///
    /// - parameters:
    ///   - row: row of matrix
    ///   - column: column of matrix
    
    public func get(row: Int, column: Int) -> Double? {
        if self.matrix.rows <= row && self.matrix.columns <= column {
            return self.matrix[row, column]
        } else {
            print("error")
            return nil
        }
    }
    
    /// Transpose Matrix Function
    /// =========================
    /// Returns result MatrixObject of transpose operation
    ///
    /// - returns: transposed MatrixObject object
    public func transpose() -> MatrixObject? {
        let result = MatrixObject(rows: self.rows, columns: self.columns)
        result.matrix = Surge.transpose(self.matrix)
        
        return result
    }
    
    /// Diagonal Matrix Function
    /// =========================
    /// Returns result MatrixObject of diagonal operation
    ///
    /// - returns: diagonal MatrixObject object
    public func diagonal() -> MatrixObject? {
        let result = MatrixObject(rows: self.rows, columns: self.columns)
        result.matrix = Surge.diagonal(self.matrix)
        
        return result
    }
    
    /// Inverse Matrix Function
    /// =======================
    /// Returns inverse matrix object
    ///
    /// - returns: inverse matrix object
    public func inverse() -> MatrixObject? {
        let result = MatrixObject(rows: rows, columns: columns)
        result.matrix = Surge.inv(self.matrix)
        
        return result
    }
    
    // MARK: - Predefined MatrixObject operators
    
    /// Predefined + operator
    /// =====================
    /// Returns result MatrixObject of addition operation
    ///
    /// - parameters:
    ///   - lhs: left addition MatrixObject operand
    ///   - rhs: right addition MatrixObject operand
    /// - returns: result MatrixObject object of addition operation
    static func + (lhs: MatrixObject, rhs: MatrixObject) -> MatrixObject? {
        let result = MatrixObject(rows: lhs.rows, columns: lhs.columns)
        result.matrix = Surge.add(lhs.matrix, rhs.matrix)
        
        return result
    }
    
    /// Predefined - operator
    /// =====================
    /// Returns result MatrixObject of subtraction operation
    ///
    /// - parameters:
    ///   - lhs: left subtraction MatrixObject operand
    ///   - rhs: right subtraction MatrixObject operand
    /// - returns: result MatrixObject object of subtraction operation
    static func - (lhs: MatrixObject, rhs: MatrixObject) -> MatrixObject? {
        let result = MatrixObject(rows: lhs.rows, columns: lhs.columns)
        
        if (lhs.rows == rhs.rows && lhs.columns == rhs.columns) {
            for row in 0..<lhs.matrix.rows {
                for column in 0..<lhs.matrix.columns {
                    result.matrix[row, column] = lhs.matrix[row, column] - rhs.matrix[row, column]
                }
            }
        }
        
        return result
    }
    
    /// Predefined * operator
    /// =====================
    /// Returns result MatrixObject of multiplication operation
    ///
    /// - parameters:
    ///   - lhs: left multiplication MatrixObject operand
    ///   - rhs: right multiplication MatrixObject operand
    /// - returns: result MatrixObject object of multiplication operation
    static func * (lhs: MatrixObject, rhs: MatrixObject) -> MatrixObject? {
        let resultMatrix = Surge.mul(lhs.matrix, rhs.matrix)
        let result = MatrixObject(rows: resultMatrix.rows,columns: resultMatrix.columns)
        result.matrix = resultMatrix
        
        return result
    }
}
