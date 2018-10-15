USE AdventureWorks2014;

SELECT c.*, st.Name, st.CountryRegionCode
FROM Sales.Customer c
JOIN Sales.SalesTerritory st
	ON c.TerritoryID = st.TerritoryID
FOR XML RAW;

SELECT c.*, st.Name, st.CountryRegionCode
FROM Sales.Customer c
JOIN Sales.SalesTerritory st
	ON c.TerritoryID = st.TerritoryID
FOR XML RAW, ELEMENTS, ROOT('Customers');

SELECT *
--SELECT Sales.SalesTerritory.*, Sales.Customer.* -- check the order/grouping now
FROM Sales.Customer
JOIN Sales.SalesTerritory
	ON Customer.TerritoryID = SalesTerritory.TerritoryID
FOR XML AUTO;

SELECT *
FROM Sales.Customer c -- aliases
JOIN Sales.SalesTerritory st
	ON c.TerritoryID = st.TerritoryID
FOR XML AUTO;

SELECT *
FROM Sales.Customer c
JOIN Sales.SalesTerritory st
	ON c.TerritoryID = st.TerritoryID
FOR XML AUTO, ELEMENTS;

-- FOR XML AUTO + NAMESPACE + ELEMENTS instead of ARGUMENTS
WITH XMLNAMESPACES('TK461-Customers' AS co)
SELECT 
	[co:Customer].CustomerID AS [co:custid],
	[co:Customer].AccountNumber AS [co:AccountNumber]
FROM Sales.Customer AS [co:Customer]
WHERE [co:Customer].CustomerID <= 102
ORDER BY [co:Customer].CustomerID
FOR XML AUTO, ELEMENTS, ROOT('CustomersData');

-- SCHEMA
SELECT 
	[Customer].CustomerID AS [custid],
	[Customer].AccountNumber AS [AccountNumber]
FROM Sales.Customer AS [Customer]
WHERE [Customer].CustomerID <= 102
ORDER BY [Customer].CustomerID
FOR XML AUTO, ELEMENTS,	XMLSCHEMA('TK461-Customers');

-- FOR XML PATH
SELECT 
	[Customer].CustomerID AS [@custid],
	[Customer].AccountNumber AS [AccountNumber],
	[Territorrrry].*
FROM Sales.Customer as [Customer]
JOIN Sales.SalesTerritory as [Territorrrry]
	ON [Customer].TerritoryID = [Territorrrry].TerritoryID
WHERE [Customer].CustomerID <= 102
ORDER BY [Customer].CustomerID
FOR XML PATH('CustomerElem'), ROOT('CustomersData');

-- XQuery
select * from databaselog
select * from Person.Person
select * from Production.Illustration
select * from Production.ProductModel
select * from Sales.Store;

DECLARE @x AS XML;
SET @x='
	<CustomersOrders>
		<Customer custid="1" companyname="Customer NRZBB">
			<Order orderid="10692" orderdate="2007-10-03T00:00:00" />
			<Order orderid="10702" orderdate="2007-10-13T00:00:00" />
			<Order orderid="10952" orderdate="2008-03-16T00:00:00" />
		</Customer>
		<Customer custid="2" companyname="Customer MLTDN">
			<Order orderid="10308" orderdate="2006-09-18T00:00:00" />
			<Order orderid="10926" orderdate="2008-03-04T00:00:00" />
		</Customer>
	</CustomersOrders>';
SELECT @x.query('
	for $i in //Customer
	return
	<OrdersInfo>
		{ $i/@companyname }
		<NumberOfOrders>
			{ count($i/Order) }
		</NumberOfOrders>
		<LastOrder>
			{ max($i/Order/@orderid) }
		</LastOrder>
	</OrdersInfo>
');
go;

DECLARE @x AS XML = N'
	<Employee empid="2">
		<FirstName>fname</FirstName>
		<LastName>lname</LastName>
	</Employee>
';
DECLARE @v AS NVARCHAR(20) = N'FirstName';
SELECT @x.query('
	if (sql:variable("@v")="FirstName") then
		/Employee/FirstName
	else
		/Employee/LastName
') AS FirstOrLastName;
go;

-- FLWOR Expressions
DECLARE @x AS XML;
SET @x = N'
<CustomersOrders>
	<Customer custid="1">
		<!-- Comment 111 -->
		<companyname>Customer NRZBB</companyname>
		<Order orderid="10692">
			<orderdate>2007-10-03T00:00:00</orderdate>
		</Order>
		<Order orderid="10702">
			<orderdate>2007-10-13T00:00:00</orderdate>
		</Order>
		<Order orderid="10952">
			<orderdate>2008-03-16T00:00:00</orderdate>
		</Order>
	</Customer>
	<Customer custid="2">
		<!-- Comment 222 -->
		<companyname>Customer MLTDN</companyname>
		<Order orderid="10308">
			<orderdate>2006-09-18T00:00:00</orderdate>
		</Order>
		<Order orderid="10952">
			<orderdate>2008-03-04T00:00:00</orderdate>
		</Order>
	</Customer>
</CustomersOrders>';
SELECT @x.query('
	for $i in CustomersOrders/Customer/Order
	let $j := $i/orderdate
	where $i/@orderid < 10900
	order by ($j)[1]
	return
		<Order-orderid-element>
			<orderid>{data($i/@orderid)}</orderid>
			{$j}
		</Order-orderid-element>
') AS [Filtered, sorted and reformatted orders with let clause];

-- XPath Expressions { Node-name/child::element-name[@attribute-name=value] }
SELECT @x.query('CustomersOrders/Customer/node()') AS [2. All nodes]; 
--comment(), node(), processing-instruction(), text()

-- XML Data Type Methods
SELECT @x.value('(/CustomersOrders/Customer/companyname)[1]',
'NVARCHAR(20)')
AS [First Customer Name];

SELECT @x.exist('(/CustomersOrders/Customer/companyname)') AS [Company Name Exists],
@x.exist('(/CustomersOrders/Customer/address)') AS [Address Exists];

SELECT 
	T.c.value('./@orderid[1]', 'INT') AS [Order Id],
	T.c.value('./orderdate[1]', 'DATETIME') AS [Order Date]
FROM @x.nodes('//Customer[@custid=1]/Order') AS T(c);

SET @x.modify('
	replace value of
		/CustomersOrders[1]/Customer[1]/companyname[1]/text()[1]
	with "New Company Name"');
SELECT @x.value('(/CustomersOrders/Customer/companyname)[1]', 'NVARCHAR(20)')
	AS [First Customer New Name];