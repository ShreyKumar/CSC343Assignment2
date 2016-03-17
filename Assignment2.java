import java.sql.*;
// You should use this class so that you can represent SQL points as
// Java PGpoint objects.
import org.postgresql.geometric.PGpoint;
import java.sql.Timestamp;

import java.lang.Math;
import java.util.Date;

// If you are looking for Java data structures, these are highly useful.
// However, you can write the solution without them.  And remember
// that part of your mark is for doing as much in SQL (not Java) as you can.
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Set;

public class Assignment2 {

   // A connection to the database
   Connection connection;

   Assignment2() throws SQLException {
      try {
         Class.forName("org.postgresql.Driver");
      } catch (ClassNotFoundException e) {
         e.printStackTrace();
      }
   }

  /**
   * Connects and sets the search path.
   *
   * Establishes a connection to be used for this session, assigning it to
   * the instance variable 'connection'.  In addition, sets the search
   * path to uber.
   *
   * @param  url       the url for the database
   * @param  username  the username to connect to the database
   * @param  password  the password to connect to the database
   * @return           true if connecting is successful, false otherwise
   */
   public boolean connectDB(String URL, String username, String password) {
      // Implement this method!
	  
	  PreparedStatement pStatement;
	  String query;
	  boolean query_sucess = false;
	  int insert_query = 0;
	  
	  try {
		connection = DriverManager.getConnection(URL, username, password);
		query = "SET search_path TO uber, public";
		pStatement = connection.prepareStatement(query);
		query_sucess = pStatement.execute();
	  } catch(SQLException e){
		e.printStackTrace();
		return false;
	  }
	  
	  return connection != null;
   }

  /**
   * Closes the database connection.
   *
   * @return true if the closing was successful, false otherwise
   */
   public boolean disconnectDB() {
      // Implement this method!
	  try {
		connection.close();
		return connection == null;
      } catch(Exception e){
		return false;
	  }
   }
   
   /* ======================= Driver-related methods ======================= */

   /**
    * Records the fact that a driver has declared that he or she is available 
    * to pick up a client.  
    *
    * Does so by inserting a row into the Available table.
    * 
    * @param  driverID  id of the driver
    * @param  when      the date and time when the driver became available
    * @param  location  the coordinates of the driver at the time when 
    *                   the driver became available
    * @return           true if the insertion was successful, false otherwise. 
    */
   public boolean available(int driverID, Timestamp when, PGpoint location) {
      // Implement this method!
	  PreparedStatement pStatement;
	  String query;
	  boolean query_sucess;
	  int insert_query = 0;
	  try {
		  query = "insert into available values " + "(" + driverID + ", " + when + ", (" + location.x + ", " + location.y + "));";
		  pStatement = connection.prepareStatement(query);
		  System.out.println(query);
		  pStatement.executeUpdate();
	  } catch(Exception e){
		e.printStackTrace();
		System.out.println("hello");
		return false;
	  }
	  
      return insert_query > 0;
   }

   /**
    * Records the fact that a driver has picked up a client.
    *
    * If the driver was dispatched to pick up the client and the corresponding
    * pick-up has not been recorded, records it by adding a row to the
    * Pickup table, and returns true.  Otherwise, returns false.
    * 
    * @param  driverID  id of the driver
    * @param  clientID  id of the client
    * @param  when      the date and time when the pick-up occurred
    * @return           true if the operation was successful, false otherwise
    */
   public boolean picked_up(int driverID, int clientID, Timestamp when) {
      // Implement this method!
	  PreparedStatement pStatement;
	  String queryString;
	  boolean query_sucess;
	  ResultSet rs;
	  int insert_query;
	  try {
		Connection conn = null;
		int count = 0;
		  Statement stmt = null;
		  queryString = "SET search_path TO uber, public";
		  pStatement = connection.prepareStatement(queryString);
		  query_sucess = pStatement.execute();
		  
		//first check if there are any rows in pickup where the corresponding request_id 
		queryString = "select count(request_id) from pickup where" + 
		"request_id=(select request.request_id from " +
		"dispatch inner join request on" + 
		"dispatch.request_id=request.request_id where" + 
		"client_id=" + clientID + " and driver_id=" + driverID + ");";
		
	    pStatement = conn.prepareStatement(queryString);
	    rs = pStatement.executeQuery();
	    
	    while(rs.next()){
			count = rs.getInt("count");
	    }
		
		if(count == 0){
			queryString = "insert into pickup values ((select request.request_id from" + 
			"request inner join dispatch on" + 
			"request.request_id=dispatch.request_id where" + 
			"client_id=" + clientID + " and driver_id=" + driverID + "), when)";
			
			pStatement = conn.prepareStatement(queryString);
			boolean done = pStatement.execute();
			
			return done; 
		} else {
			return false;
		}
		
	  } catch(Exception e){
		return false;
	  }
	  
   }
   
   /* ===================== Dispatcher-related methods ===================== */

   /**
    * Dispatches drivers to the clients who've requested rides in the area
    * bounded by NW and SE.
    * 
    * For all clients who have requested rides in this area (i.e., whose 
    * request has a source location in this area), dispatches drivers to them
    * one at a time, from the client with the highest total billings down
    * to the client with the lowest total billings, or until there are no
    * more drivers available.
    *
    * Only drivers who (a) have declared that they are available and have 
    * not since then been dispatched, and (b) whose location is in the area
    * bounded by NW and SE, are dispatched.  If there are several to choose
    * from, the one closest to the client's source location is chosen.
    * In the case of ties, any one of the tied drivers may be dispatched.
    *
    * Area boundaries are inclusive.  For example, the point (4.0, 10.0) 
    * is considered within the area defined by 
    *         NW = (1.0, 10.0) and SE = (25.0, 2.0) 
    * even though it is right at the upper boundary of the area.
    *
    * Dispatching a driver is accomplished by adding a row to the
    * Dispatch table.  All dispatching that results from a call to this
    * method is recorded to have happened at the same time, which is
    * passed through parameter 'when'.
    * 
    * @param  NW    x, y coordinates in the northwest corner of this area.
    * @param  SE    x, y coordinates in the southeast corner of this area.
    * @param  when  the date and time when the dispatching occurred
    */
   public void dispatch(PGpoint NW, PGpoint SE, Timestamp when) {
      // Implement this method!
	  Connection conn;
	  PreparedStatement pStatement;
	  String queryString;
	  boolean query_sucess;
	  ResultSet rs;
	  int count;
	  
	  try{
		  conn = null;
	  	  queryString = "SET search_path TO uber, public";
		  pStatement = connection.prepareStatement(queryString);
		  query_sucess = pStatement.execute();
		  
		//first check if there are any rows in pickup where the corresponding request_id 
		queryString = "select count(driver_id) from dispatch where driver_id=(select driver_id from available);";
		
	    pStatement = conn.prepareStatement(queryString);
	    rs = pStatement.executeQuery();
	    
	    while(rs.next()){
			count = rs.getInt("count");
	    }
		
		//check second if statement
		
		String findDriverID = "select driver_id from availble where " + Math.min(NW.x, SE.x) + " <= location[0]" + 
		"AND " + Math.max(NW.x, SE.x) + " >= location[0]" +
		"AND " + Math.min(NW.y, SE.y) + " <= location[1]" +
		"AND " + Math.max(NW.y, SE.y) + " >= location[1]  order by location limit 1";
		String findCarLocation = "select location from availble where " + Math.min(NW.x, SE.x) + " <= location[0]" + 
		"AND " + Math.max(NW.x, SE.x) + " >= location[0]" +
		"AND " + Math.min(NW.y, SE.y) + " <= location[1]" +
		"AND " + Math.max(NW.y, SE.y) + " >= location[1] order by location limit 1";
		
		//find the most recent request ID that has been recorded as a request but has not been recorded as dispatched
		String findRequestID = "select request.request_id from dispatch inner join request on request.request_id!=dispatch.request_id" + 
		"order by request.datetime limit 1";
		
		queryString = "insert into dispatch values((" + findRequestID + "), (" + findDriverID + "), (" + findCarLocation +"), " + when + ")";
		
		pStatement = conn.prepareStatement(queryString);
		boolean done = pStatement.execute();
		
		} catch(SQLException e){
		
		}
	  
   }
   
   

   public static void main(String[] args) {
      // You can put testing code in here. It will not affect our autotester.
      System.out.println("Boo!");
	  
	  try {
		  System.out.println("connectDB");
		  Assignment2 a2 = new Assignment2();
		  if(a2.connectDB("jdbc:postgresql://localhost:5432/csc343h-g5kumars", "g5kumars", "")){
			System.out.println("worked");
		  } else {
			System.out.println("didnt work");
		  };
		  
		  System.out.println("disconnect");
		  a2.disconnectDB();
		  
		  System.out.println("insert available");
		  PGpoint point = new PGpoint(3.0, 5.0);
		  java.util.Date date= new java.util.Date();
		  
		  Timestamp time = new Timestamp(date.getTime());
		  if(a2.available(12345, time, point)){
			System.out.println("done");
		  } else {
			System.out.println("not done");
		  }
		} catch(SQLException e){
		  e.printStackTrace();
		}
	  
   }

}
