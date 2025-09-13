CREATE DATABASE StudentAnalytics;
USE StudentAnalytics;

CREATE TABLE Students (
	StudentID INT IDENTITY(1,1) PRIMARY KEY,
    StudentName VARCHAR(100) NOT NULL,
    ClassName VARCHAR(50) NOT NULL,   
    Gender CHAR(1) NULL,             
    DOB DATE NULL
);

CREATE TABLE Subjects(
	SubjectID INT IDENTITY(1,1) PRIMARY KEY,
	SubjectName VARCHAR (100) NOT NULL
	);


	CREATE TABLE Marks(
		MarkID INT IDENTITY(1,1) PRIMARY KEY,
		StudentID INT NOT NULL,
		SubjectID INT NOT NULL,
		Score INT NOT NULL CHECK (Score BETWEEN 0 AND 100),
		Term VARCHAR(20) DEFAULT 'Term1',
		ExamDate Date NULL,
		CONSTRAINT FK_Marks_Students FOREIGN KEY (StudentID) REFERENCES Students(StudentID),
		CONSTRAINT FK_Marks_Subjects FOREIGN KEY (SubjectID) REFERENCES Subjects(SubjectID),
		CONSTRAINT UQ_Marks_Student_Subject_Term UNIQUE (StudentID, SubjectID, Term)
		);

INSERT INTO Subjects (SubjectName)
VALUES
('Mathematics'),
('English'),
('Science'),
('History'),
('Geography'),
('Sinhala'),
('ICT'),
('Commerce');

DECLARE @i INT = 1;
WHILE @i <= 500
BEGIN
    INSERT INTO Students (StudentName, ClassName, Gender)
    VALUES (
        CONCAT('Student', @i),
        CASE 
            WHEN @i % 4 = 1 THEN 'Grade 10' 
            WHEN @i % 4 = 2 THEN 'Grade 11'
            WHEN @i % 4 = 3 THEN 'Grade 12'
            ELSE 'Grade 13' 
        END,
        CASE WHEN @i % 2 = 0 THEN 'M' ELSE 'F' END
    );

    SET @i = @i + 1;
END;


SELECT TOP 10 * FROM Students;

INSERT INTO Marks (StudentID, SubjectID, Score, Term, ExamDate)
SELECT
    s.StudentID,
    subj.SubjectID,
    ABS(CHECKSUM(NEWID())) % 101 AS Score,  -- random 0..100
    'Term1',
    DATEADD(day, ABS(CHECKSUM(NEWID())) % 365, '2024-01-01') AS ExamDate
FROM Students s
CROSS JOIN Subjects subj;

SELECT COUNT(*) AS MarksCount FROM Marks;  
SELECT TOP 10 * FROM Marks;                -- see sample mark rows
CREATE INDEX IX_Marks_StudentID ON Marks(StudentID);
CREATE INDEX IX_Marks_SubjectID ON Marks(SubjectID);

SELECT
    subj.SubjectName,
    ROUND(AVG(CAST(m.Score AS FLOAT)), 2) AS AvgScore
FROM Marks m
JOIN Subjects subj ON m.SubjectID = subj.SubjectID
GROUP BY subj.SubjectName
ORDER BY AvgScore DESC;

-------Top 3 students per subject

WITH Ranked AS (
    SELECT
        m.SubjectID,
        subj.SubjectName,
        s.StudentID,
        s.StudentName,
        m.Score,
        RANK() OVER (PARTITION BY m.SubjectID ORDER BY m.Score DESC) AS rnk
    FROM Marks m
    JOIN Students s ON m.StudentID = s.StudentID
    JOIN Subjects subj ON m.SubjectID = subj.SubjectID
)
SELECT
    SubjectName,
    rnk,
    StudentID,
    StudentName,
    Score
FROM Ranked
WHERE rnk <= 3
ORDER BY SubjectName, rnk;



WITH RankedClass AS (
    SELECT
        s.ClassName,
        subj.SubjectName,
        s.StudentID, s.StudentName,
        m.Score,
        RANK() OVER (PARTITION BY subj.SubjectID, s.ClassName ORDER BY m.Score DESC) AS rnk
    FROM Marks m
    JOIN Students s ON m.StudentID = s.StudentID
    JOIN Subjects subj ON m.SubjectID = subj.SubjectID
)
SELECT ClassName, SubjectName, rnk, StudentID, StudentName, Score
FROM RankedClass
WHERE rnk <= 3
ORDER BY ClassName, SubjectName, rnk;

----------------Identify students who failed more than 2 subjects
SELECT
    s.StudentID,
    s.StudentName,
    s.ClassName,
    SUM(CASE WHEN m.Score < 40 THEN 1 ELSE 0 END) AS FailCount
FROM Marks m
JOIN Students s ON m.StudentID = s.StudentID
GROUP BY s.StudentID, s.StudentName, s.ClassName
HAVING SUM(CASE WHEN m.Score < 40 THEN 1 ELSE 0 END) > 2
ORDER BY FailCount DESC;

---------------Top 3 students per class by overall average
WITH StudentAvg AS (
    SELECT
        s.StudentID,
        s.StudentName,
        s.ClassName,
        AVG(CAST(m.Score AS FLOAT)) AS AvgScore
    FROM Marks m
    JOIN Students s ON m.StudentID = s.StudentID
    GROUP BY s.StudentID, s.StudentName, s.ClassName
),
Ranked AS (
    SELECT *,
        RANK() OVER (PARTITION BY ClassName ORDER BY AvgScore DESC) AS class_rank
    FROM StudentAvg
)
SELECT StudentID, StudentName, ClassName, ROUND(AvgScore,2) AS AvgScore, class_rank
FROM Ranked
WHERE class_rank <= 3
ORDER BY ClassName, class_rank;









	

