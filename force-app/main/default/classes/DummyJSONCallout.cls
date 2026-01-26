/*
 * DummyJSONCallout Class Description:
 * 
 * This class, DummyJSONCallout, facilitates HTTP callouts to an external system (presumably 'DummyJsonUser' in this context) 
 * to either fetch or send user information based on a given identifier. The class supports both GET (to fetch data) 
 * and POST (to send data) operations.
 * 
 * Overview of HTTP Callouts:
 * 
 * HTTP callouts are a way for Salesforce to communicate with external systems using HTTP protocols. Through HTTP callouts, 
 * you can invoke external web services, collect data from them, or send data for further processing. Apex provides 
 * classes that enable you to both send and receive HTTP data. The primary classes for this are `HttpRequest`, which 
 * represents the request you're sending, and `HttpResponse`, which represents the response you receive.
 * 
 * Best Practices:
 * 1. Handle Exceptions: Always handle exceptions that might be thrown, to ensure your code doesn't break unexpectedly.
 * 2. Named Credentials: Use Named Credentials to store endpoint URLs and authentication details securely.
 * 3. Test Callouts: Use mock classes and interfaces to test HTTP callouts without making actual callouts.
 * 
 * For more detailed information on HTTP callouts in Apex, refer to the official Salesforce documentation: 
 * https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_classes_restful_http_httprequest.htm
 */

public with sharing class DummyJSONCallout {

	/* 
	 * Question 1
     * Fetches user information from an external system https://dummyjson.com/user/{id} ('DummyJsonUser') based on the provided dummy user ID. 
     * If the callout is successful and returns an HTTP status of 200, the method will update a contact based on the DummyJSON_Id__c with the data returned from the external system.
	 * Use the createContactFromJson method to parse the JSON response and create a Salesforce Contact object.
     * Documentation: https://dummyjson.com/docs/users
	 * This callout method should work in triggers
	 * 
     * @param dummyUserId The ID of the user in the external system to fetch data for.
     */
	@future(callout=true)
	public static void getDummyJSONUserFromId(String dummyUserId) {
		
		System.debug('dummyUserId in @future :' + dummyUserId);
		
		if (dummyUserId == null || Integer.valueOf(dummyUserId) <= 100) { return; }
		
		Http dummyHttp = new Http();										// Create HTTP request to send.

		HttpRequest dummyRequest = new HttpRequest();
		dummyRequest.setEndpoint('callout:DummyJsonUser/user/' + dummyUserId);
		dummyRequest.setMethod('GET');										// Set the HTTP method to GET.
		
		string s = dummyRequest.getEndpoint();
		System.debug('getEndPoint(): ' + s);

		HttpResponse dummyResponse = dummyHttp.send(dummyRequest);			// Send the HTTP request and get the response.

		if (dummyResponse.getStatusCode() == 200) {	
			Contact cont = createContactFromJson(dummyResponse.getBody());	// If the HTTP response code is successful, parse the JSON response and update the contact.
		} else {
			System.debug('Response error code: ' + dummyResponse.getStatusCode());
		}

	}

	/* 
	 * Question 2
     * Transforms a JSON response from the external system https://dummyjson.com/users into a Salesforce Contact object.
     * The method parses the JSON string to extract user details and map them to a Salesforce Contact object.
     * The contact fields populated from the JSON include Email, Phone, Birthdate, and various address-related fields.
     * The method is primarily designed to work in conjunction with callouts that fetch user details from the external system. 
	 * 
	 * Fields from JSON used to populate Salesforce Contact
	 * Fields: Email, Phone, Birthdate, MailingStreet, MailingCity, MailingPostalCode, MailingState, MailingCountry
	 * 
     * Documentation: https://dummyjson.com/docs/users
     * 
     * @param String jsonResponse The JSON string from the external system that contains user details.
     * @return Contact The Salesforce Contact object populated with details from the JSON string.
     */
	@TestVisible // Allows test class to see this method. Since it is private, it would not be visible otherwise.
	private static Contact createContactFromJson(String jsonResponse) {
		
		Contact cont = new Contact(); 				

		Map<String, Object> mapResponse = (Map<String,Object>)JSON.deserializeUntyped(jsonResponse); // Deserialize the JSON string into map of primitive data types.
		//System.debug('mapResponse: ' + JSON.serializePretty(mapResponse));
		cont.FirstName = (String)mapResponse?.get('firstName');
		cont.LastName = (String)mapResponse?.get('lastName');
		cont.Birthdate = Utilities.convertStringToDate((String)mapResponse?.get('birthDate'));		
		cont.Email = (String)mapResponse?.get('email');
		cont.Phone = (String)mapResponse?.get('phone');

		cont.DummyJSON_Last_Updated__c = Datetime.now();

		Map<String, Object> mapAddress = (Map<String,Object>)mapResponse.get('address');  	// Deserialize the address from the JSON response.
		//System.debug('mapAddress: ' + JSON.serializePretty(mapAddress));
		cont.MailingStreet = (String)mapAddress?.get('address');							// Set the address fields on the contact.
		cont.MailingCity = (String)mapAddress?.get('city');
		cont.MailingPostalCode = (String)mapAddress?.get('postalCode');
		cont.MailingState = (String)mapAddress?.get('stateCode');
		cont.MailingCountry = (String)mapAddress?.get('country');
		//System.debug('cont: ' + JSON.serializePretty(cont));

		return cont;
	}

	/* 
	 * Question 3
     * Sends Contact information to an external system https://dummyjson.com/users/add ('DummyJsonUser') to create or update a user based on the provided Salesforce Contact ID.
     * The method prepares a JSON payload with the contact's information and sends it to the 'DummyJsonUser' add endpoint.
     * If the callout is successful (HTTP status code between 200 and 299), the method updates the contact's 'DummyJSON_Last_Updated__c' field in Salesforce to the current time.
	 * Salesforce Contact should be used to generate the JSON payload
	 * Fields: Id, FirstName, LastName, Email, Phone
	 * This callout method should work in triggers
	 * 
     * Documentation: https://dummyjson.com/docs/users
     * 
     * @param contactId The Salesforce Contact ID used to generate the JSON payload for the external system.
     */
	@future(callout=true)
	public static void postCreateDummyJSONUser(String contactId) {
			
		// Use Utilities class method to validate 'contactId'
		if (!Utilities.isIdStringValid(contactId)) { return; }

		Contact dummy = [SELECT Id, DummyJSON_Id__c FROM Contact WHERE Id =:contactId];

		Http dummyPostHttp = new Http();										// Create HTTP request to send.

		HttpRequest dummyPostRequest = new HttpRequest();
		dummyPostRequest.setEndpoint('callout:DummyJsonUser/users/add/' + dummy.DummyJSON_Id__c);
		dummyPostRequest.setHeader('Content-Type', 'application/json');
		dummyPostRequest.setMethod('POST');										// Set the HTTP method to POST.
		if (generateDummyJsonUserPayload(contactId) == 'invalid JSON') {return;} // Exit callout if JSON is invalid.

		dummyPostRequest.setBody(generateDummyJsonUserPayload(contactId));
		
		HttpResponse dummyPostResponse = dummyPostHttp.send(dummyPostRequest);	// Send the HTTP request and get the response.

		if (dummyPostResponse.getStatusCode() >= 200 && dummyPostResponse.getStatusCode() < 300) {	
			System.debug('dummyPostResponse: ' + dummyPostResponse.getBody());
			Contact cont = new Contact();
			cont.Id = contactId;
			cont.DummyJSON_Last_Updated__c = Date.today();
			update cont;						// If the HTTP response code is successful, parse the JSON response and update the contact.
		} else {
			System.debug('Response error code: ' + dummyPostResponse.getStatusCode());
		}

	}	
	

	/*
	 * Question 4
     * Generates a JSON payload based on a Salesforce Contact's fields to be sent to an external system https://dummyjson.com/users/add for user creation or update.
     * The method queries a contact from Salesforce based on the provided contactId and maps its fields into a JSON payload.
     * The fields from Salesforce Contact that are transformed into the JSON payload include Id, FirstName, LastName, Email, and Phone.
     * The generated JSON payload can be sent to the external system for various operations like creating or updating a user.
	 * 
	 * Fields from Salesforce Contact used to generate JSON payload:
	 * Fields: Id => salesforceId, FirstName => firstName, LastName => lastName, Email => email, Phone => phone
	 * 
     * Documentation: https://dummyjson.com/docs/users
     * 
     * @param String contactId The Salesforce Contact ID used to fetch the contact's fields and generate the JSON payload.
     * @return String The JSON string payload that represents the Contact's details.
     */
	@TestVisible // Allows test class to see this method. Since it is private, it would not be visible otherwise.
	private static String generateDummyJsonUserPayload(String contactId) {
		
		Contact contPost = [SELECT Id, FirstName, LastName, Email, Phone FROM Contact WHERE Id =:contactId];
		
		Map<String,String> contPostMap = new Map<String,String>();
		contPostMap.put('salesforceId', contactId);
		contPostMap.put('firstName', contPost.FirstName ?? 'unknown');
		contPostMap.put('lastName', contPost.LastName ?? 'unknown');
		contPostMap.put('email', contPost?.Email ?? 'unknown');
		contPostMap.put('phone', contPost?.Phone ?? 'unknown');
		
		String contPostJSON = JSON.Serialize(contPostMap);
		
		// Use Utilities class method to validate contPostJSON
		if (!Utilities.isJSONStringValid(contPostJSON)) { return 'invalid JSON'; }
		
		return contPostJSON;
	}
}