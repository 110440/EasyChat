//
//  SqliteDB.swift
//  Sqlite-swift
//  mod from SwiftData

//  Created by tanson on 16/6/12.
//  Copyright © 2016年 tanson. All rights reserved.
//

import Foundation
import UIKit

private var DocPath:NSString {
    
    return NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] as NSString
}


class SqliteDB{
    
    var dbPath:String
    var sqliteDB: COpaquePointer = nil
    var isConnected = false
    let queue = dispatch_queue_create("SqliteDB.DatabaseQueue.tt", DISPATCH_QUEUE_SERIAL)
    
    init(name:String){
        self.dbPath = DocPath.stringByAppendingPathComponent(name)
        //print(DocPath)
    }
    
    deinit{
        self.close()
    }
    
    // MARK: - Database Handling Functions
    
    //open a connection to the sqlite3 database
    func open() -> Int? {
        
        if sqliteDB != nil || isConnected {
            return nil
        }
        let status = sqlite3_open(dbPath.cStringUsingEncoding(NSUTF8StringEncoding)!, &sqliteDB)
        if status != SQLITE_OK {
            print("SwiftData Error -> During: Opening Database")
            print("                -> Code: \(status) - " + SqliteError.errorMessageFromCode(Int(status)))
            if let errMsg = String.fromCString(sqlite3_errmsg(self.sqliteDB)) {
                print("                -> Details: \(errMsg)")
            }
            return Int(status)
        }
        isConnected = true
        return nil
    }

    //close the connection to to the sqlite3 database
    func close() {
        
        if sqliteDB == nil || !isConnected {
            return
        }
        let status = sqlite3_close(sqliteDB)
        if status != SQLITE_OK {
            print("SwiftData Error -> During: Closing Database")
            print("                -> Code: \(status) - " + SqliteError.errorMessageFromCode(Int(status)))
            if let errMsg = String.fromCString(sqlite3_errmsg(self.sqliteDB)) {
                print("                -> Details: \(errMsg)")
            }
        }
        sqliteDB = nil
        isConnected = false
        
    }
    
    //get last inserted row id
    func lastInsertedRowID() -> Int {
        let id = sqlite3_last_insert_rowid(sqliteDB)
        return Int(id)
    }
    
    //number of rows changed by last update
    func numberOfRowsModified() -> Int {
        return Int(sqlite3_changes(sqliteDB))
    }
    
    //return value of column
    func getColumnValue(statement: COpaquePointer, index: Int32, type: String) -> AnyObject? {
        
        switch type {
        case "INT", "INTEGER", "TINYINT", "SMALLINT", "MEDIUMINT", "BIGINT", "UNSIGNED BIG INT", "INT2", "INT8":
            if sqlite3_column_type(statement, index) == SQLITE_NULL {
                return nil
            }
            return Int(sqlite3_column_int(statement, index))
        case "CHARACTER(20)", "VARCHAR(255)", "VARYING CHARACTER(255)", "NCHAR(55)", "NATIVE CHARACTER", "NVARCHAR(100)", "TEXT", "CLOB":
            let text = UnsafePointer<Int8>(sqlite3_column_text(statement, index))
            return String.fromCString(text)
        case "BLOB", "NONE":
            let blob = sqlite3_column_blob(statement, index)
            if blob != nil {
                let size = sqlite3_column_bytes(statement, index)
                return NSData(bytes: blob, length: Int(size))
            }
            return nil
        case "REAL", "DOUBLE", "DOUBLE PRECISION", "FLOAT", "NUMERIC", "DECIMAL(10,5)":
            if sqlite3_column_type(statement, index) == SQLITE_NULL {
                return nil
            }
            return Double(sqlite3_column_double(statement, index))
        case "BOOLEAN":
            if sqlite3_column_type(statement, index) == SQLITE_NULL {
                return nil
            }
            return sqlite3_column_int(statement, index) != 0
        case "DATE", "DATETIME":
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let text = UnsafePointer<Int8>(sqlite3_column_text(statement, index))
            if let string = String.fromCString(text) {
                return dateFormatter.dateFromString(string)
            }
            print("SwiftData Warning -> The text date at column: \(index) could not be cast as a String, returning nil")
            return nil
        default:
            print("SwiftData Warning -> Column: \(index) is of an unrecognized type, returning nil")
            return nil
        }
        
    }
    
    
    // MARK: SQLite Execution Functions
    func executeChange(sqlStr:String)->Int?{
        var error: Int? = nil
        let task: ()->Void = {
            if let err = self.open() {
                error = err
                return
            }
            error = self._executeChange(sqlStr)
            //self.close()
        }
        putOnThread(task)
        return error
    }
    
    func executeChange(sqlStr: String, withArgs: [AnyObject]) -> Int? {
        
        var error: Int? = nil
        let task: ()->Void = {
            if let err = self.open() {
                error = err
                return
            }
            error = self._executeChange(sqlStr, withArgs: withArgs)
            //self.close()
        }
        putOnThread(task)
        return error
    }
    
    //execute a SQLite update from a SQL String
    private func _executeChange(sqlStr: String, withArgs: [AnyObject]? = nil) -> Int? {
        
        var sql = sqlStr
        if let args = withArgs {
            let result = bind(args, toSQL: sql)
            if let error = result.error {
                return error
            } else {
                sql = result.string
            }
        }
        var pStmt: COpaquePointer = nil
        var status = sqlite3_prepare_v2(self.sqliteDB, sql, -1, &pStmt, nil)
        if status != SQLITE_OK {
            print("SwiftData Error -> During: SQL Prepare")
            print("                -> Code: \(status) - " + SqliteError.errorMessageFromCode(Int(status)))
            if let errMsg = String.fromCString(sqlite3_errmsg(self.sqliteDB)) {
                print("                -> Details: \(errMsg)")
            }
            sqlite3_finalize(pStmt)
            return Int(status)
        }
        status = sqlite3_step(pStmt)
        if status != SQLITE_DONE && status != SQLITE_OK {
            print("SwiftData Error -> During: SQL Step")
            print("                -> Code: \(status) - " + SqliteError.errorMessageFromCode(Int(status)))
            if let errMsg = String.fromCString(sqlite3_errmsg(self.sqliteDB)) {
                print("                -> Details: \(errMsg)")
            }
            sqlite3_finalize(pStmt)
            return Int(status)
        }
        sqlite3_finalize(pStmt)
        return nil
        
    }
    
    
    //execute a SQLite query from a SQL String
    
    func executeQuery(sqlStr: String) -> (result: [SDRow], error: Int?) {
        
        var result = [SDRow] ()
        var error: Int? = nil
        let task: ()->Void = {
            if let err = self.open() {
                error = err
                return
            }
            (result, error) = self._executeQuery(sqlStr)
            //self.close()
        }
        putOnThread(task)
        return (result, error)
        
    }
    

    func executeQuery(sqlStr: String, withArgs: [AnyObject]) -> (result: [SDRow], error: Int?) {
        
        var result = [SDRow] ()
        var error: Int? = nil
        let task: ()->Void = {
            if let err = self.open() {
                error = err
                return
            }
            (result, error) = self._executeQuery(sqlStr, withArgs: withArgs)
            //self.close()
        }
        putOnThread(task)
        return (result, error)
    }
    
    private func _executeQuery(sqlStr: String, withArgs: [AnyObject]? = nil) -> (result: [SDRow], error: Int?) {
        
        var resultSet = [SDRow]()
        var sql = sqlStr
        if let args = withArgs {
            let result = bind(args, toSQL: sql)
            if let err = result.error {
                return (resultSet, err)
            } else {
                sql = result.string
            }
        }
        var pStmt: COpaquePointer = nil
        var status = sqlite3_prepare_v2(self.sqliteDB, sql, -1, &pStmt, nil)
        if status != SQLITE_OK {
            print("SwiftData Error -> During: SQL Prepare")
            print("                -> Code: \(status) - " + SqliteError.errorMessageFromCode(Int(status)))
            if let errMsg = String.fromCString(sqlite3_errmsg(self.sqliteDB)) {
                print("                -> Details: \(errMsg)")
            }
            sqlite3_finalize(pStmt)
            return (resultSet, Int(status))
        }
        var columnCount: Int32 = 0
        var next = true
        while next {
            status = sqlite3_step(pStmt)
            if status == SQLITE_ROW {
                columnCount = sqlite3_column_count(pStmt)
                var row = SDRow()
                for i: Int32 in 0 ..< columnCount {
                    let columnName = String.fromCString(sqlite3_column_name(pStmt, i))!
                    if let columnType = String.fromCString(sqlite3_column_decltype(pStmt, i))?.uppercaseString {
                        if let columnValue: AnyObject = getColumnValue(pStmt, index: i, type: columnType) {
                            row[columnName] = SDColumn(obj: columnValue)
                        }
                    } else {
                        var columnType = ""
                        switch sqlite3_column_type(pStmt, i) {
                        case SQLITE_INTEGER:
                            columnType = "INTEGER"
                        case SQLITE_FLOAT:
                            columnType = "FLOAT"
                        case SQLITE_TEXT:
                            columnType = "TEXT"
                        case SQLITE3_TEXT:
                            columnType = "TEXT"
                        case SQLITE_BLOB:
                            columnType = "BLOB"
                        case SQLITE_NULL:
                            columnType = "NULL"
                        default:
                            columnType = "NULL"
                        }
                        if let columnValue: AnyObject = getColumnValue(pStmt, index: i, type: columnType) {
                            row[columnName] = SDColumn(obj: columnValue)
                        }
                    }
                }
                resultSet.append(row)
            } else if status == SQLITE_DONE {
                next = false
            } else {
                print("SwiftData Error -> During: SQL Step")
                print("                -> Code: \(status) - " + SqliteError.errorMessageFromCode(Int(status)))
                if let errMsg = String.fromCString(sqlite3_errmsg(self.sqliteDB)) {
                    print("                -> Details: \(errMsg)")
                }
                sqlite3_finalize(pStmt)
                return (resultSet, Int(status))
            }
        }
        sqlite3_finalize(pStmt)
        return (resultSet, nil)
        
    }

    //QueryCount
//    
//    func executeQueryCount(sqlStr: String) -> (count:Int32, error: Int?) {
//        
//        var count:Int32 = 0
//        var error: Int? = nil
//        let task: ()->Void = {
//            if let err = self.open() {
//                error = err
//                return
//            }
//            (count, error) = self._executeQueryCount(sqlStr, withArgs: nil)
//            //self.close()
//        }
//        putOnThread(task)
//        return (count, error)
//    }
//    
//    private func _executeQueryCount(sqlStr: String, withArgs: [AnyObject]? = nil) -> (count:Int32, error: Int?) {
//        
//        var sql = sqlStr
//        if let args = withArgs {
//            let result = bind(args, toSQL: sql)
//            if let err = result.error {
//                return (0, err)
//            } else {
//                sql = result.string
//            }
//        }
//        var pStmt: COpaquePointer = nil
//        var status = sqlite3_prepare_v2(self.sqliteDB, sql, -1, &pStmt, nil)
//        if status != SQLITE_OK {
//            print("SwiftData Error -> During: SQL Prepare")
//            print("                -> Code: \(status) - " + SqliteError.errorMessageFromCode(Int(status)))
//            if let errMsg = String.fromCString(sqlite3_errmsg(self.sqliteDB)) {
//                print("                -> Details: \(errMsg)")
//            }
//            sqlite3_finalize(pStmt)
//            return (0, Int(status))
//        }
//        var columnCount: Int32 = 0
//        
//        status = sqlite3_step(pStmt)
//        if status == SQLITE_ROW {
//            columnCount = sqlite3_column_count(pStmt)
//        }else if status == SQLITE_DONE {
//        }else{
//            print("SwiftData Error -> During: SQL Step")
//            print("                -> Code: \(status) - " + SqliteError.errorMessageFromCode(Int(status)))
//            if let errMsg = String.fromCString(sqlite3_errmsg(self.sqliteDB)) {
//                print("                -> Details: \(errMsg)")
//            }
//            sqlite3_finalize(pStmt)
//            return (0, Int(status))
//
//        }
//        sqlite3_finalize(pStmt)
//        return (columnCount, Int(status))
//    }
    
}


//MARK:

enum SqliteDataType {
    
    case StringVal
    case IntVal
    case DoubleVal
    case BoolVal
    case DataVal
    case DateVal
    case UIImageVal
    
    private func toSQL() -> String {
        
        switch self {
        case .StringVal, .UIImageVal:
            return "TEXT"
        case .IntVal:
            return "INTEGER"
        case .DoubleVal:
            return "DOUBLE"
        case .BoolVal:
            return "BOOLEAN"
        case .DataVal:
            return "BLOB"
        case .DateVal:
            return "DATE"
        }
    }
    
}


//MARK: table
extension SqliteDB {
    
    
    func createTable(table: String, withColumnNamesAndTypes values: [String: SqliteDataType]) -> Int? {
        
        var error: Int? = nil
        let task: ()->Void = {
            if let err = self.open() {
                error = err
                return
            }
            error = self._createSQLTable(table, withColumnsAndTypes: values)
            //self.close()
        }
        putOnThread(task)
        
        return error
        
    }
    
 
   func deleteTable(table: String) -> Int? {
        
        var error: Int? = nil
        let task: ()->Void = {
            if let err = self.open() {
                error = err
                return
            }
            error = self._deleteSQLTable(table)
            //self.close()
        }
        putOnThread(task)
        return error
        
    }
    
  
    func GetExistingTables() -> (result: [String], error: Int?) {
        
        var result = [String] ()
        var error: Int? = nil
        let task: ()->Void = {
            if let err = self.open() {
                error = err
                return
            }
            (result, error) = self._existingTables()
            //self.close()
        }
        putOnThread(task)
        return (result, error)
        
    }
    
    //create a table
    private func _createSQLTable(table: String, withColumnsAndTypes values: [String: SqliteDataType]) -> Int? {
        
        var sqlStr = "CREATE TABLE IF NOT EXISTS \(table) (ID INTEGER PRIMARY KEY AUTOINCREMENT, "
        var firstRun = true
        for value in values {
            if firstRun {
                sqlStr += "\(escapeIdentifier(value.0)) \(value.1.toSQL())"
                firstRun = false
            } else {
                sqlStr += ", \(escapeIdentifier(value.0)) \(value.1.toSQL())"
            }
        }
        sqlStr += ")"
        return _executeChange(sqlStr)
    }
    
    //delete a table
    private func _deleteSQLTable(table: String) -> Int? {
        let sqlStr = "DROP TABLE \(table)"
        return _executeChange(sqlStr)
    }
    
    //get existing table names
    private func _existingTables() -> (result: [String], error: Int?) {
        let sqlStr = "SELECT name FROM sqlite_master WHERE type = 'table'"
        var tableArr = [String]()
        let results = _executeQuery(sqlStr)
        if let err = results.error {
            return (tableArr, err)
        }
        for row in results.result {
            if let table = row["name"]?.asString() {
                tableArr.append(table)
            } else {
                print("SwiftData Error -> During: Finding Existing Tables")
                print("                -> Code: 403 - Error extracting table names from sqlite_master")
                return (tableArr, 403)
            }
        }
        return (tableArr, nil)
    }
}

// MARK: Bind
extension SqliteDB {
    
    func bind(objects: [AnyObject], toSQL sql: String) -> (string: String, error: Int?) {
        
        var newSql = ""
        var bindIndex = 0
        var i = false
        for char in sql.characters {
            if char == "?" {
                if bindIndex > objects.count - 1 {
                    print("SwiftData Error -> During: Object Binding")
                    print("                -> Code: 201 - Not enough objects to bind provided")
                    return ("", 201)
                }
                var obj = ""
                if i {
                    if let str = objects[bindIndex] as? String {
                        obj = escapeIdentifier(str)
                    } else {
                        print("SwiftData Error -> During: Object Binding")
                        print("                -> Code: 203 - Object to bind as identifier must be a String at array location: \(bindIndex)")
                        return ("", 203)
                    }
                    newSql = newSql.substringToIndex(newSql.endIndex.predecessor())
                } else {
                    obj = escapeValue(objects[bindIndex])
                }
                newSql += obj
                bindIndex += 1
            } else {
                newSql.append(char)
            }
            if char == "i" {
                i = true
            } else if i {
                i = false
            }
        }
        if bindIndex != objects.count {
            print("SwiftData Error -> During: Object Binding")
            print("                -> Code: 202 - Too many objects to bind provided")
            return ("", 202)
        }
        return (newSql, nil)
        
    }
    
    //return escaped String value of AnyObject
    func escapeValue(obj: AnyObject?) -> String {
        
        if let obj: AnyObject = obj {
            if obj is String {
                return "'\(escapeStringValue(obj as! String))'"
            }
            if obj is Double || obj is Int {
                return "\(obj)"
            }
            if obj is Bool {
                if obj as! Bool {
                    return "1"
                } else {
                    return "0"
                }
            }
            if obj is NSData {
                let str = "\(obj)"
                var newStr = ""
                for char in str.characters {
                    if char != "<" && char != ">" && char != " " {
                        newStr.append(char)
                    }
                }
                return "X'\(newStr)'"
            }
            if obj is NSDate {
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                return "\(escapeValue(dateFormatter.stringFromDate(obj as! NSDate)))"
            }
   
            print("SwiftData Warning -> Object \"\(obj)\" is not a supported type and will be inserted into the database as NULL")
            return "NULL"
        } else {
            return "NULL"
        }
        
    }
    
    //return escaped String identifier
    func escapeIdentifier(obj: String) -> String {
        return "\"\(escapeStringIdentifier(obj))\""
    }
    
    
    //escape string
    func escapeStringValue(str: String) -> String {
        var escapedStr = ""
        for char in str.characters {
            if char == "'" {
                escapedStr += "'"
            }
            escapedStr.append(char)
        }
        return escapedStr
    }
    
    //escape string
    func escapeStringIdentifier(str: String) -> String {
        var escapedStr = ""
        for char in str.characters {
            if char == "\"" {
                escapedStr += "\""
            }
            escapedStr.append(char)
        }
        return escapedStr
    }
    
}

extension SqliteDB {
    
    private func putOnThread(task: ()->Void) {
        
        dispatch_sync(self.queue) {
            task()
        }
        
    }
    
}



// MARK: - SDRow

public struct SDRow {
    
    var values = [String: SDColumn]()
    public subscript(key: String) -> SDColumn? {
        get {
            return values[key]
        }
        set(newValue) {
            values[key] = newValue
        }
    }
    
}


// MARK: - SDColumn

public struct SDColumn {
    
    var value: AnyObject
    init(obj: AnyObject) {
        value = obj
    }
    
    //return value by type
    
    /**
     Return the column value as a String
     
     :returns:  An Optional String corresponding to the apprioriate column value. Will be nil if: the column name does not exist, the value cannot be cast as a String, or the value is NULL
     */
    public func asString() -> String? {
        return value as? String
    }
    
    /**
     Return the column value as an Int
     
     :returns:  An Optional Int corresponding to the apprioriate column value. Will be nil if: the column name does not exist, the value cannot be cast as a Int, or the value is NULL
     */
    public func asInt() -> Int? {
        return value as? Int
    }
    
    /**
     Return the column value as a Double
     
     :returns:  An Optional Double corresponding to the apprioriate column value. Will be nil if: the column name does not exist, the value cannot be cast as a Double, or the value is NULL
     */
    public func asDouble() -> Double? {
        return value as? Double
    }
    
    /**
     Return the column value as a Bool
     
     :returns:  An Optional Bool corresponding to the apprioriate column value. Will be nil if: the column name does not exist, the value cannot be cast as a Bool, or the value is NULL
     */
    public func asBool() -> Bool? {
        return value as? Bool
    }
    
    /**
     Return the column value as NSData
     
     :returns:  An Optional NSData object corresponding to the apprioriate column value. Will be nil if: the column name does not exist, the value cannot be cast as NSData, or the value is NULL
     */
    public func asData() -> NSData? {
        return value as? NSData
    }
    
    /**
     Return the column value as an NSDate
     
     :returns:  An Optional NSDate corresponding to the apprioriate column value. Will be nil if: the column name does not exist, the value cannot be cast as an NSDate, or the value is NULL
     */
    public func asDate() -> NSDate? {
        return value as? NSDate
    }
    
    /**
     Return the column value as an AnyObject
     
     :returns:  An Optional AnyObject corresponding to the apprioriate column value. Will be nil if: the column name does not exist, the value cannot be cast as an AnyObject, or the value is NULL
     */
    public func asAnyObject() -> AnyObject? {
        return value
    }
    
}

//MARK:- SqliteError

class SqliteError {
    
    //get the error message from the error code
    static func errorMessageFromCode(errorCode: Int) -> String {
        
        switch errorCode {
            
            //no error
            
        case -1:
            return "No error"
            
        //SQLite error codes and descriptions as per: http://www.sqlite.org/c3ref/c_abort.html
        case 0:
            return "Successful result"
        case 1:
            return "SQL error or missing database"
        case 2:
            return "Internal logic error in SQLite"
        case 3:
            return "Access permission denied"
        case 4:
            return "Callback routine requested an abort"
        case 5:
            return "The database file is locked"
        case 6:
            return "A table in the database is locked"
        case 7:
            return "A malloc() failed"
        case 8:
            return "Attempt to write a readonly database"
        case 9:
            return "Operation terminated by sqlite3_interrupt()"
        case 10:
            return "Some kind of disk I/O error occurred"
        case 11:
            return "The database disk image is malformed"
        case 12:
            return "Unknown opcode in sqlite3_file_control()"
        case 13:
            return "Insertion failed because database is full"
        case 14:
            return "Unable to open the database file"
        case 15:
            return "Database lock protocol error"
        case 16:
            return "Database is empty"
        case 17:
            return "The database schema changed"
        case 18:
            return "String or BLOB exceeds size limit"
        case 19:
            return "Abort due to constraint violation"
        case 20:
            return "Data type mismatch"
        case 21:
            return "Library used incorrectly"
        case 22:
            return "Uses OS features not supported on host"
        case 23:
            return "Authorization denied"
        case 24:
            return "Auxiliary database format error"
        case 25:
            return "2nd parameter to sqlite3_bind out of range"
        case 26:
            return "File opened that is not a database file"
        case 27:
            return "Notifications from sqlite3_log()"
        case 28:
            return "Warnings from sqlite3_log()"
        case 100:
            return "sqlite3_step() has another row ready"
        case 101:
            return "sqlite3_step() has finished executing"
            
            //custom SwiftData errors
            
            //->binding errors
            
        case 201:
            return "Not enough objects to bind provided"
        case 202:
            return "Too many objects to bind provided"
        case 203:
            return "Object to bind as identifier must be a String"
            
            //->custom connection errors
            
        case 301:
            return "A custom connection is already open"
        case 302:
            return "Cannot open a custom connection inside a transaction"
        case 303:
            return "Cannot open a custom connection inside a savepoint"
        case 304:
            return "A custom connection is not currently open"
        case 305:
            return "Cannot close a custom connection inside a transaction"
        case 306:
            return "Cannot close a custom connection inside a savepoint"
            
            //->index and table errors
            
        case 401:
            return "At least one column name must be provided"
        case 402:
            return "Error extracting index names from sqlite_master"
        case 403:
            return "Error extracting table names from sqlite_master"
            
            //->transaction and savepoint errors
            
        case 501:
            return "Cannot begin a transaction within a savepoint"
        case 502:
            return "Cannot begin a transaction within another transaction"
            
            //unknown error
            
        default:
            //what the fuck happened?!?
            return "Unknown error"
        }
    }
}