USE SocialMediaDB;
GO

-- =============================================================================
-- EXAMPLE OF INDEXES FOR PERFORMANCE OPTIMIZATION
-- =============================================================================

BEGIN TRANSACTION;

CREATE INDEX IX_Audit_FieldName ON Audit (FieldName);

CREATE UNIQUE INDEX IX_Audit_Id ON Audit (Id);

CREATE INDEX IX_Audit_PerformerId ON Audit (PerformerId);

CREATE INDEX IX_Audit_PerformerIp ON Audit (PerformerIp);

CREATE INDEX IX_Audit_RecordId ON Audit (RecordId);

CREATE INDEX IX_Audit_TableName ON Audit (TableName);

CREATE UNIQUE INDEX IX_Chat_Id ON Chat (Id);

CREATE INDEX IX_ChatParticipant_ChatId ON ChatParticipant (ChatId);

CREATE UNIQUE INDEX IX_ChatParticipant_Id ON ChatParticipant (Id);

CREATE INDEX IX_ChatParticipant_RoleId ON ChatParticipant (RoleId);

CREATE INDEX IX_ChatParticipant_UserId ON ChatParticipant (UserId);

CREATE UNIQUE INDEX IX_ChatParticipantRole_Id ON ChatParticipantRole (Id);

CREATE INDEX IX_CommentLikes_CommentId ON CommentLikes (CommentId);

CREATE INDEX IX_CommentLikes_UserId ON CommentLikes (UserId);

CREATE INDEX IX_Comments_CreatorId ON Comments (CreatorId);

CREATE UNIQUE INDEX IX_Comments_Id ON Comments (Id);

CREATE INDEX IX_Comments_RelatedPublicationId ON Comments (RelatedPublicationId);

CREATE INDEX IX_Comments_ReplyToCommentId ON Comments (ReplyToCommentId);

CREATE INDEX IX_Follows_FollowedUserId ON Follows (FollowedUserId);

CREATE INDEX IX_Follows_UserId ON Follows (UserId);

CREATE INDEX IX_Message_ChatId ON Message (ChatId);

CREATE UNIQUE INDEX IX_Message_Id ON Message (Id);

CREATE INDEX IX_Message_ReplyToMessageId ON Message (ReplyToMessageId);

CREATE INDEX IX_Message_SenderId ON Message (SenderId);

CREATE UNIQUE INDEX IX_MessageLike_Id ON MessageLike (Id);

CREATE INDEX IX_MessageLike_MessageId ON MessageLike (MessageId);

CREATE INDEX IX_MessageLike_UserId ON MessageLike (UserId);

CREATE INDEX IX_PublicationLikes_PublicationId ON PublicationLikes (PublicationId);

CREATE INDEX IX_PublicationLikes_UserId ON PublicationLikes (UserId);

CREATE INDEX IX_Publications_CreatorId ON Publications (CreatorId);

CREATE UNIQUE INDEX IX_Publications_Id ON Publications (Id);

CREATE UNIQUE INDEX IX_RefreshTokens_Id ON RefreshTokens (Id);

CREATE UNIQUE INDEX IX_RefreshTokens_UserId ON RefreshTokens (UserId);

CREATE UNIQUE INDEX IX_Report_Id ON Report (Id);

CREATE INDEX IX_Report_ReporterId ON Report (ReporterId);

CREATE INDEX IX_Report_ResolvedById ON Report (ResolvedById);

CREATE INDEX IX_Report_TargetId ON Report (TargetId);

CREATE INDEX IX_Report_TargetType ON Report (TargetType);

CREATE INDEX IX_UserRestriction_ImposedByUserId ON UserRestriction (ImposedByUserId);

CREATE UNIQUE INDEX IX_UserRestriction_TargetUserId ON UserRestriction (TargetUserId);

CREATE INDEX IX_UserRestriction_Type ON UserRestriction (Type);

CREATE UNIQUE INDEX IX_UserRole_Name ON UserRole (Name);

CREATE UNIQUE INDEX IX_Users_Email ON Users (Email);

CREATE UNIQUE INDEX IX_Users_Id ON Users (Id);

CREATE UNIQUE INDEX IX_Users_Login ON Users (Login);

CREATE UNIQUE INDEX IX_Users_RefreshTokenId ON Users (RefreshTokenId);

CREATE INDEX IX_Users_RoleId ON Users (RoleId);

COMMIT;
GO


-- =============================================================================
-- EXAMPLE OF TRIGGER FOR AUDIT LOGGING
-- =============================================================================

-- Audit trigger for Users table
CREATE TRIGGER TR_Users_Audit
ON Users
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Action NVARCHAR(10);
    DECLARE @PerformerId UNIQUEIDENTIFIER = NEWID();
    -- In real app, get from session context
    DECLARE @PerformerIp NVARCHAR(64) = '127.0.0.1';
    -- In real app, get from session context

    -- Determine action
    IF EXISTS(SELECT *
        FROM inserted) AND EXISTS(SELECT *
        FROM deleted)
        SET @Action = 'UPDATE'
    ELSE IF EXISTS(SELECT *
    FROM inserted)
        SET @Action = 'INSERT'
    ELSE
        SET @Action = 'DELETE'

    -- Log changes for UPDATE
    IF @Action = 'UPDATE'
    BEGIN
        INSERT INTO Audit
            (Id, TableName, FieldName, RecordId, OldValue, NewValue, Action, PerformerId, PerformerIp, PerformedAt)
                                    SELECT
                NEWID(),
                'Users',
                'Login',
                COALESCE(i.Id, d.Id),
                ISNULL(d.Login, ''),
                ISNULL(i.Login, ''),
                @Action,
                @PerformerId,
                @PerformerIp,
                GETDATE()
            FROM inserted i FULL OUTER JOIN deleted d ON i.Id = d.Id
            WHERE ISNULL(i.Login, '') != ISNULL(d.Login, '')

        UNION ALL

            SELECT
                NEWID(),
                'Users',
                'Email',
                COALESCE(i.Id, d.Id),
                ISNULL(d.Email, ''),
                ISNULL(i.Email, ''),
                @Action,
                @PerformerId,
                @PerformerIp,
                GETDATE()
            FROM inserted i FULL OUTER JOIN deleted d ON i.Id = d.Id
            WHERE ISNULL(i.Email, '') != ISNULL(d.Email, '')

        UNION ALL

            SELECT
                NEWID(),
                'Users',
                'FirstName',
                COALESCE(i.Id, d.Id),
                ISNULL(d.FirstName, ''),
                ISNULL(i.FirstName, ''),
                @Action,
                @PerformerId,
                @PerformerIp,
                GETDATE()
            FROM inserted i FULL OUTER JOIN deleted d ON i.Id = d.Id
            WHERE ISNULL(i.FirstName, '') != ISNULL(d.FirstName, '')

        UNION ALL

            SELECT
                NEWID(),
                'Users',
                'LastName',
                COALESCE(i.Id, d.Id),
                ISNULL(d.LastName, ''),
                ISNULL(i.LastName, ''),
                @Action,
                @PerformerId,
                @PerformerIp,
                GETDATE()
            FROM inserted i FULL OUTER JOIN deleted d ON i.Id = d.Id
            WHERE ISNULL(i.LastName, '') != ISNULL(d.LastName, '');
    END

    -- Log INSERT/DELETE
    IF @Action IN ('INSERT', 'DELETE')
    BEGIN
        INSERT INTO Audit
            (Id, TableName, FieldName, RecordId, OldValue, NewValue, Action, PerformerId, PerformerIp, PerformedAt)
        SELECT
            NEWID(),
            'Users',
            'Record',
            COALESCE(i.Id, d.Id),
            CASE WHEN @Action = 'DELETE' THEN 'EXISTS' ELSE '' END,
            CASE WHEN @Action = 'INSERT' THEN 'EXISTS' ELSE '' END,
            @Action,
            @PerformerId,
            @PerformerIp,
            GETDATE()
        FROM inserted i FULL OUTER JOIN deleted d ON i.Id = d.Id;
    END
END;
GO


-- =============================================================================
-- EXAMPLE OF FIELD CONSTRAINTS
-- =============================================================================

-- Email format validation
ALTER TABLE Users
ADD CONSTRAINT CK_Users_Email_Format 
CHECK (Email LIKE '%_@_%._%' AND Email NOT LIKE '%@%@%');

-- Login format validation (3-30 characters, letters, digits, underscores only)
ALTER TABLE Users
ADD CONSTRAINT CK_Users_Login_Format 
CHECK (Login NOT LIKE '%[^A-Za-z0-9_]%' AND LEN(Login) BETWEEN 3 AND 30);

-- Publication description length constraint
ALTER TABLE Publications
ADD CONSTRAINT CK_Publications_Description_Length 
CHECK (LEN(LTRIM(RTRIM(Description))) >= 1 AND LEN(Description) <= 1000);

-- Publication creation date cannot be in the future
ALTER TABLE Publications
ADD CONSTRAINT CK_Publications_CreationDateTime 
CHECK (CreationDateTime <= GETDATE());

-- Users cannot follow themselves
ALTER TABLE Follows
ADD CONSTRAINT CK_Follows_NoSelfFollow 
CHECK (UserId != FollowedUserId);

GO


-- =============================================================================
-- EXAMPLE OF DATABASE VIEWS
-- =============================================================================

-- 1. User profiles with comprehensive statistics
CREATE VIEW VW_UserProfiles
AS
    SELECT
        u.Id,
        u.Login,
        u.Email,
        u.FirstName,
        u.LastName,
        u.Bio,
        ur.Name as RoleName,
        (SELECT COUNT(*)
        FROM Follows f
        WHERE f.UserId = u.Id) as FollowingCount,
        (SELECT COUNT(*)
        FROM Follows f
        WHERE f.FollowedUserId = u.Id) as FollowersCount,
        (SELECT COUNT(*)
        FROM Publications p
        WHERE p.CreatorId = u.Id) as PublicationsCount
    FROM Users u
        INNER JOIN UserRole ur ON u.RoleId = ur.Id;
GO

-- 2. Publications with detailed engagement metrics
CREATE VIEW VW_PublicationsWithStats
AS
    SELECT
        p.Id,
        p.Description,
        p.CreationDateTime,
        p.CreatorId,
        u.Login as CreatorLogin,
        u.FirstName + ' ' + u.LastName as CreatorFullName,
        (SELECT COUNT(*)
        FROM PublicationLikes pl
        WHERE pl.PublicationId = p.Id) as LikesCount,
        (SELECT COUNT(*)
        FROM Comments c
        WHERE c.RelatedPublicationId = p.Id) as CommentsCount
    FROM Publications p
        INNER JOIN Users u ON p.CreatorId = u.Id;
GO

-- 3. Personalized user feed for followed users' content
CREATE VIEW VW_UserFeed
AS
    SELECT
        f.UserId as ViewerId,
        p.Id as PublicationId,
        p.Description,
        p.CreationDateTime,
        p.CreatorId,
        u.Login as CreatorLogin,
        u.FirstName + ' ' + u.LastName as CreatorFullName,
        (SELECT COUNT(*)
        FROM PublicationLikes pl
        WHERE pl.PublicationId = p.Id) as LikesCount,
        (SELECT COUNT(*)
        FROM Comments c
        WHERE c.RelatedPublicationId = p.Id) as CommentsCount
    FROM Follows f
        INNER JOIN Publications p ON f.FollowedUserId = p.CreatorId
        INNER JOIN Users u ON p.CreatorId = u.Id;
GO


-- =============================================================================
-- EXAMPLE OF STORED PROCEDURES
-- =============================================================================

-- 1. Create new publication with automatic ID generation
CREATE PROCEDURE SP_CreatePublication
    @CreatorId UNIQUEIDENTIFIER,
    @Description NVARCHAR(1000),
    @ImageData NVARCHAR(MAX) = NULL,
    @PublicationId UNIQUEIDENTIFIER OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Generate new unique ID for the publication
    SET @PublicationId = NEWID();

    -- Insert new publication with current timestamp
    INSERT INTO Publications
        (Id, Description, ImageData, CreationDateTime, CreatorId)
    VALUES
        (@PublicationId, @Description, @ImageData, DATEADD(SECOND, -1, GETDATE()), @CreatorId);

    -- Return the generated publication ID
    SELECT @PublicationId as PublicationId;
END;
GO

-- 2. Get user profile with comprehensive statistics
CREATE PROCEDURE SP_GetUserProfile
    @UserId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    -- Return user profile data from the view
    SELECT *
    FROM VW_UserProfiles
    WHERE Id = @UserId;
END;
GO

-- 3. Toggle follow/unfollow relationship between users
CREATE PROCEDURE SP_ToggleFollow
    @UserId UNIQUEIDENTIFIER,
    @TargetUserId UNIQUEIDENTIFIER,
    @IsFollowing BIT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Prevent users from following themselves
    IF @UserId = @TargetUserId
    BEGIN
        RAISERROR('Users cannot follow themselves', 16, 1);
        RETURN;
    END

    -- Check current follow status
    IF EXISTS(SELECT 1
    FROM Follows
    WHERE UserId = @UserId AND FollowedUserId = @TargetUserId)
    BEGIN
        -- Unfollow operation
        DELETE FROM Follows WHERE UserId = @UserId AND FollowedUserId = @TargetUserId;
        SET @IsFollowing = 0;
    END
    ELSE
    BEGIN
        -- Follow operation
        INSERT INTO Follows
            (Id, UserId, FollowedUserId)
        VALUES
            (NEWID(), @UserId, @TargetUserId);
        SET @IsFollowing = 1;
    END

    -- Return the result status
    SELECT @IsFollowing as IsFollowing;
END;
GO