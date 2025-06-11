USE SocialMediaDB;
GO


-- =============================================================================
-- AUDIT TRIGGER TEST
-- =============================================================================

-- Clean up existing test data
DELETE FROM RefreshTokens WHERE Id='bca9d46b-1b62-48b1-afe2-cc7de633b2c8';
DELETE FROM Users WHERE Login='drwal';
DELETE FROM Audit WHERE TableName='Users';

-- Test 1: INSERT
PRINT '1. Testing INSERT...';

INSERT INTO RefreshTokens
    (Id, Token, TokenExpiryTime, UserId)
VALUES
    ('bca9d46b-1b62-48b1-afe2-cc7de633b2c8', 'refresh_token__d_rwal__12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890', DATEADD(day, 30, GETDATE()), '1edf0a7c-75ca-4b8c-bfb1-061c126f91ce');

INSERT INTO Users
    (Id, Login, PasswordHash, Email, FirstName, LastName, Bio, ProfileImageData, RoleId, RefreshTokenId)
VALUES
    ('1edf0a7c-75ca-4b8c-bfb1-061c126f91ce', 'drwal', 'hashed_password_john_123456789012345678901234567890123456789012345678901234567890123456789012345678901234567', 'drwal@email.com', 'Dan', 'Mark', '', NULL, '5fe0adee-241f-44d5-837f-745980dabe1f', 'bca9d46b-1b62-48b1-afe2-cc7de633b2c8');


DECLARE @UserId UNIQUEIDENTIFIER = (SELECT Id
FROM Users
WHERE Login = 'drwal');

-- Check INSERT audit
SELECT 'INSERT Result:' AS Test, COUNT(*) AS AuditRecords
FROM Audit
WHERE Action = 'INSERT' AND RecordId = @UserId;

-- Test 2: UPDATE
PRINT '2. Testing UPDATE...';
UPDATE Users
SET Email = 'updated@example.com', FirstName = 'Dan'
WHERE Id = @UserId;

-- Check UPDATE audit
SELECT 'UPDATE Result:' AS Test, FieldName, OldValue, NewValue
FROM Audit
WHERE Action = 'UPDATE' AND RecordId = @UserId;

-- Test 3: DELETE
PRINT '3. Testing DELETE...';
DELETE FROM Users WHERE Id = @UserId;

-- Check DELETE audit
SELECT 'DELETE Result:' AS Test, COUNT(*) AS AuditRecords
FROM Audit
WHERE Action = 'DELETE' AND RecordId = @UserId;

-- SUMMARY of audit actions for the test user
PRINT 'Summary of audit actions:';
SELECT Action, COUNT(*) AS TotalRecords
FROM Audit
WHERE RecordId = @UserId
GROUP BY Action;


-- =============================================================================
-- POPULATE DB TEST 
-- =============================================================================

PRINT 'Verifying record counts in tables:';
    SELECT 'Audit' AS TableName, COUNT(*) AS RecordCount
    FROM Audit
UNION ALL
    SELECT 'Chat', COUNT(*)
    FROM Chat
UNION ALL
    SELECT 'ChatParticipantRole', COUNT(*)
    FROM ChatParticipantRole
UNION ALL
    SELECT 'RefreshTokens', COUNT(*)
    FROM RefreshTokens
UNION ALL
    SELECT 'UserRole', COUNT(*)
    FROM UserRole
UNION ALL
    SELECT 'Users', COUNT(*)
    FROM Users
UNION ALL
    SELECT 'ChatParticipant', COUNT(*)
    FROM ChatParticipant
UNION ALL
    SELECT 'Follows', COUNT(*)
    FROM Follows
UNION ALL
    SELECT 'Message', COUNT(*)
    FROM Message
UNION ALL
    SELECT 'Publications', COUNT(*)
    FROM Publications
UNION ALL
    SELECT 'Report', COUNT(*)
    FROM Report
UNION ALL
    SELECT 'UserRestriction', COUNT(*)
    FROM UserRestriction
UNION ALL
    SELECT 'MessageLike', COUNT(*)
    FROM MessageLike
UNION ALL
    SELECT 'Comments', COUNT(*)
    FROM Comments
UNION ALL
    SELECT 'PublicationLikes', COUNT(*)
    FROM PublicationLikes
UNION ALL
    SELECT 'CommentLikes', COUNT(*)
    FROM CommentLikes;
GO

-- =============================================================================
-- TESTING FIELD CONSTRAINTS
-- =============================================================================

-- Clean up existing test data
DELETE FROM RefreshTokens WHERE Id='bca9d46b-1b62-48b1-afe2-cc7de633b2c8';
DELETE FROM Users WHERE Login='drwal';

-- Insert required refresh token for user creation tests
INSERT INTO RefreshTokens
    (Id, Token, TokenExpiryTime, UserId)
VALUES
    ('bca9d46b-1b62-48b1-afe2-cc7de633b2c8', 'refresh_token__d_rwal__12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890', DATEADD(day, 30, GETDATE()), '1edf0a7c-75ca-4b8c-bfb1-061c126f91ce');

PRINT '=== TESTING FIELD CONSTRAINTS ===';

-- Test 1: Attempt to create user with invalid email format
PRINT 'Test 1: Invalid email format';
BEGIN TRY
INSERT INTO Users
    (Id, Login, PasswordHash, Email, FirstName, LastName, Bio, ProfileImageData, RoleId, RefreshTokenId)
VALUES
    ('1edf0a7c-75ca-4b8c-bfb1-061c126f91ce', 'drwal', 'hashed_password_john_123456789012345678901234567890123456789012345678901234567890123456789012345678901234567', 'invlaid_email', 'Dan', 'Mark', '', NULL, '5fe0adee-241f-44d5-837f-745980dabe1f', 'bca9d46b-1b62-48b1-afe2-cc7de633b2c8');
    PRINT 'ERROR: Constraint did not work!';
END TRY
BEGIN CATCH
    PRINT 'SUCCESS: ' + ERROR_MESSAGE();
END CATCH;

-- Test 2: Attempt to create user with too short login
PRINT 'Test 2: Login too short';
BEGIN TRY
INSERT INTO Users
    (Id, Login, PasswordHash, Email, FirstName, LastName, Bio, ProfileImageData, RoleId, RefreshTokenId)
VALUES
    ('1edf0a7c-75ca-4b8c-bfb1-061c126f91ce', 'a', 'hashed_password_john_123456789012345678901234567890123456789012345678901234567890123456789012345678901234567', 'drwal@email.com', 'Dan', 'Mark', '', NULL, '5fe0adee-241f-44d5-837f-745980dabe1f', 'bca9d46b-1b62-48b1-afe2-cc7de633b2c8');
    PRINT 'ERROR: Constraint did not work!';
END TRY
BEGIN CATCH
    PRINT 'SUCCESS: ' + ERROR_MESSAGE();
END CATCH;

-- Test 3: Attempt to create publication with empty description
PRINT 'Test 3: Empty publication description';
BEGIN TRY
    INSERT INTO Publications
    (Id, Description, CreationDateTime, CreatorId)
VALUES
    (NEWID(), '', GETDATE(), (SELECT TOP 1
            Id
        FROM Users));
    PRINT 'ERROR: Constraint did not work!';
END TRY
BEGIN CATCH
    PRINT 'SUCCESS: ' + ERROR_MESSAGE();
END CATCH;

-- Test 4: Attempt to follow oneself
PRINT 'Test 4: Self-follow attempt';
BEGIN TRY
    DECLARE @TestUserId UNIQUEIDENTIFIER = (SELECT TOP 1
    Id
FROM Users);
    INSERT INTO Follows
    (Id, UserId, FollowedUserId)
VALUES
    (NEWID(), @TestUserId, @TestUserId);
    PRINT 'ERROR: Constraint did not work!';
END TRY
BEGIN CATCH
    PRINT 'SUCCESS: ' + ERROR_MESSAGE();
END CATCH;

PRINT '';
GO


-- =============================================================================
-- TESTING DATABASE VIEWS
-- =============================================================================

PRINT 'Testing VW_UserProfiles...';
SELECT *
FROM VW_UserProfiles;
GO

PRINT 'Testing VW_PublicationsWithStats...';
SELECT *
FROM VW_PublicationsWithStats;
GO

PRINT 'Testing VW_UserFeed...';
SELECT *
FROM VW_UserFeed;
GO


-- =============================================================================
-- STORED PROCEDURE TESTS
-- =============================================================================

DECLARE @TestUser1 UNIQUEIDENTIFIER;
DECLARE @TestUser2 UNIQUEIDENTIFIER;

-- Test users
SELECT TOP 1
    @TestUser1 = Id
FROM Users
ORDER BY Login;
SELECT TOP 1
    @TestUser2 = Id
FROM Users
WHERE Id != @TestUser1
ORDER BY Login;

PRINT '=== SP_CreatePublication Tests ===';

-- Test 1: Basic publication creation
PRINT 'Test 1: Creating basic publication...';
DECLARE @PublicationId UNIQUEIDENTIFIER;
EXEC SP_CreatePublication
        @CreatorId = @TestUser1,
    @Description = 'Test publication',
        @PublicationId = @PublicationId OUTPUT;

-- Test 2: Publication with image
PRINT CHAR(13) + 'Test 2: Creating publication with image...';
DECLARE @PublicationId2 UNIQUEIDENTIFIER;
EXEC SP_CreatePublication
        @CreatorId = @TestUser1,
    @Description = 'Test with image',
    @ImageData = 'base64imagedata',
        @PublicationId = @PublicationId2 OUTPUT;

PRINT CHAR(13) + '=== SP_GetUserProfile Tests ===';

-- Test 3: Get existing user profile
PRINT 'Test 3: Getting existing user profile...';
EXEC SP_GetUserProfile @UserId = @TestUser1;

-- Test 4: Get non-existent user
PRINT CHAR(13) + 'Test 4: Getting non-existent user profile...';
DECLARE @FakeUserId UNIQUEIDENTIFIER = NEWID();
EXEC SP_GetUserProfile @UserId = @FakeUserId;

PRINT CHAR(13) + '=== SP_ToggleFollow Tests ===';

-- Test 5: Follow user
PRINT 'Test 5: Following user...';
DECLARE @IsFollowing BIT;
EXEC SP_ToggleFollow
        @UserId = @TestUser1,
        @TargetUserId = @TestUser2,
        @IsFollowing = @IsFollowing OUTPUT;

-- Test 6: Unfollow user (toggle again)
PRINT CHAR(13) + 'Test 6: Toggling follow again (should unfollow)...';
EXEC SP_ToggleFollow
        @UserId = @TestUser1,
        @TargetUserId = @TestUser2,
        @IsFollowing = @IsFollowing OUTPUT;

-- Test 7: Self-follow attempt (should fail)
PRINT CHAR(13) + 'Test 7: Attempting self-follow (should fail)...';
EXEC SP_ToggleFollow
        @UserId = @TestUser1,
        @TargetUserId = @TestUser1,
        @IsFollowing = @IsFollowing OUTPUT;