IF OBJECT_ID('SP_SearchTables','P') IS NOT NULL
	DROP PROCEDURE SP_SearchTables
GO
CREATE PROCEDURE SP_SearchTables
 @Tablenames VARCHAR(500)
,@SearchStr NVARCHAR(60)
,@GenerateSQLOnly Bit = 0
AS

/*
	Parameters and usage

	@Tablenames		-- Provide a single table name or multiple table name with comma seperated. 
						If left blank , it will check for all the tables in the database
						Provide wild card tables names with comma seperated
						EX :'%tbl%,Dim%' -- This will search the table having names comtains "tbl" and starts with "Dim"
							
	@SearchStr		-- Provide the search string. Use the '%' to coin the search. Also can provide multiple search with comma seperated
						EX : X%--- will give data staring with X
							 %X--- will give data ending with X
							 %X%--- will give data containig  X
							 %X%,Y%--- will give data containig  X or starting with Y
							 %X%,%,,% -- Use a double comma to search comma in the data
	@GenerateSQLOnly -- Provide 1 if you only want to generate the SQL statements without seraching the database. 
						By default it is 0 and it will search.

	Samples :

	1. To search data in a table

		EXEC SP_SearchTables @Tablenames = 'T1'
						 ,@SearchStr  = '%TEST%'

		The above sample searches in table T1 with string containing TEST.

	2. To search in a multiple table

		EXEC SP_SearchTables @Tablenames = 'T2'
						 ,@SearchStr  = '%TEST%'

		The above sample searches in tables T1 & T2 with string containing TEST.
	
	3. To search in a all table

		EXEC SP_SearchTables @Tablenames = '%'
						 ,@SearchStr  = '%TEST%'

		The above sample searches in all table with string containing TEST.

	4. Generate the SQL for the Select statements

		EXEC SP_SearchTables @Tablenames		= 'T1'
						 ,@SearchStr		= '%TEST%'
						 ,@GenerateSQLOnly	= 1

	5. To Search in tables with specfic name

		EXEC SP_SearchTables @Tablenames		= '%T1%'
						 ,@SearchStr		= '%TEST%'
						 ,@GenerateSQLOnly	= 0

	6. To Search in multiple tables with specfic names

		EXEC SP_SearchTables @Tablenames		= '%T1%,Dim%'
						 ,@SearchStr		= '%TEST%'
						 ,@GenerateSQLOnly	= 0
	
	7. To specify multiple search strings

		EXEC SP_SearchTables @Tablenames		= '%T1%,Dim%'
						 ,@SearchStr		= '%TEST%,TEST1%,%TEST2'
						 ,@GenerateSQLOnly	= 0


	8. To search comma itself in the tables use double comma ",,"

		EXEC SP_SearchTables @Tablenames		= '%T1%,Dim%'
						 ,@SearchStr		= '%,,%'
						 ,@GenerateSQLOnly	= 0

		EXEC SP_SearchTables @Tablenames		= '%T1%,Dim%'
						 ,@SearchStr		= '%with,,comma%'
						 ,@GenerateSQLOnly	= 0
*/

	SET NOCOUNT ON

	DECLARE @MatchFound BIT

	SELECT @MatchFound = 0

	DECLARE @CheckTableNames Table
	(
	Tablename sysname
	)

	DECLARE @SearchStringTbl TABLE
	(
	SearchString VARCHAR(500)
	)

	DECLARE @SQLTbl TABLE
	(
	 Tablename		SYSNAME
	,WHEREClause    VARCHAR(MAX)
	,SQLStatement   VARCHAR(MAX)
	,Execstatus		BIT 
	)

	DECLARE @SQL VARCHAR(MAX)
	DECLARE @TblSQL VARCHAR(MAX)
	DECLARE @tmpTblname sysname
	DECLARE @ErrMsg VARCHAR(100)

	IF LTRIM(RTRIM(@Tablenames)) IN ('' ,'%')
	BEGIN

		INSERT INTO @CheckTableNames
		SELECT Name
		  FROM sys.tables
	END
	ELSE
	BEGIN

		IF CHARINDEX(',',@Tablenames) > 0 
			SELECT @SQL = 'SELECT ''' + REPLACE(@Tablenames,',','''as TblName UNION SELECT ''') + ''''
		ELSE
			SELECT @SQL = 'SELECT ''' + @Tablenames + ''' as TblName '

		SELECT @TblSQL = 'SELECT T.NAME
							FROM SYS.TABLES T
							JOIN (' + @SQL + ') tblsrc
							 ON T.name LIKE tblsrc.tblname '


		

		INSERT INTO @CheckTableNames
		EXEC(@TblSQL)

	END
	
	IF NOT EXISTS(SELECT 1 FROM @CheckTableNames)
	BEGIN
		
		SELECT @ErrMsg = 'No tables are found in this database ' + DB_NAME() + ' for the specified filter'
		PRINT @ErrMsg
		RETURN

	END


	IF LTRIM(RTRIM(@SearchStr)) =''
	BEGIN

		SELECT @ErrMsg = 'Please specify the search string in @SearchStr Parameter'
		PRINT @ErrMsg
		RETURN
	END
	ELSE
	BEGIN 
		SELECT @SearchStr = REPLACE(@SearchStr,',,,',',#DOUBLECOMMA#')
		SELECT @SearchStr = REPLACE(@SearchStr,',,','#DOUBLECOMMA#')

		SELECT @SQL = 'SELECT ''' + REPLACE(@SearchStr,',','''as SearchString UNION SELECT ''') + ''''

		INSERT INTO @SearchStringTbl
		(SearchString)
		EXEC(@SQL)

		UPDATE @SearchStringTbl
		   SET SearchString = REPLACE(SearchString ,'#DOUBLECOMMA#',',')
	END

	
	
	INSERT INTO @SQLTbl
	( Tablename,WHEREClause)
	SELECT QUOTENAME(SCh.name) + '.' + QUOTENAME(ST.NAME),
			(
				SELECT '[' + SC.Name + ']' + ' LIKE ''' + SearchSTR.SearchString + ''' OR ' + CHAR(10)
				  FROM SYS.columns SC
				  JOIN SYS.types STy
					ON STy.system_type_id = SC.system_type_id
				   AND STy.user_type_id =SC.user_type_id
				  CROSS JOIN @SearchStringTbl SearchSTR
				 WHERE STY.name in ('varchar','char','nvarchar','nchar','text')
				   AND SC.object_id = ST.object_id
				 ORDER BY SC.name
				FOR XML PATH('')
			)
	  FROM  SYS.tables ST
	  JOIN @CheckTableNames chktbls
				ON chktbls.Tablename = ST.name 
	  JOIN SYS.schemas SCh
	    ON ST.schema_id = SCh.schema_id
	 WHERE ST.name <> 'SearchTMP'
      GROUP BY ST.object_id, QUOTENAME(SCh.name) + '.' +  QUOTENAME(ST.NAME) ;
	

	  UPDATE @SQLTbl
		 SET SQLStatement = 'SELECT * INTO SearchTMP FROM ' + Tablename + ' WHERE ' + substring(WHEREClause,1,len(WHEREClause)-5)


		 
	  DELETE FROM @SQLTbl
	   WHERE WHEREClause IS NULL
	
	WHILE EXISTS (SELECT 1 FROM @SQLTbl WHERE ISNULL(Execstatus ,0) = 0)
	BEGIN

		SELECT TOP 1 @tmpTblname = Tablename , @SQL = SQLStatement
		  FROM @SQLTbl 
		 WHERE ISNULL(Execstatus ,0) = 0

		 IF @GenerateSQLOnly = 0
		 BEGIN

			IF OBJECT_ID('SearchTMP','U') IS NOT NULL
				DROP TABLE SearchTMP
				
			EXEC (@SQL)

			IF EXISTS(SELECT 1 FROM SearchTMP)
			BEGIN
				SELECT Tablename=@tmpTblname,* FROM SearchTMP
				SELECT @MatchFound = 1
			END

		 END
		 ELSE
		 BEGIN
			 PRINT REPLICATE('-',100)
			 PRINT @tmpTblname
			 PRINT REPLICATE('-',100)
			 PRINT replace(@SQL,'INTO SearchTMP','')
		 END

		 UPDATE @SQLTbl
		    SET Execstatus = 1
		  WHERE Tablename = @tmpTblname

	END

	IF @MatchFound = 0 
	BEGIN
		SELECT @ErrMsg = 'No Matches are found in this database ' + DB_NAME() + ' for the specified filter'
		PRINT @ErrMsg
		RETURN
	END
	
	SET NOCOUNT OFF

go


