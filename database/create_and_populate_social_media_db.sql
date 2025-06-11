/*
================================================================================
  START OF DATABASE CREATION SECTION
  This part includes all the statements for creating the database schema:
  - Defining tables with their columns and data types
  - Setting up primary keys and foreign keys
  - Creating constraints
  - Establishing relationships between tables
  This section lays the foundation for the database structure before inserting data.
================================================================================
*/

USE master;
GO

BEGIN TRY
    IF NOT EXISTS (
        SELECT name
FROM sys.databases
WHERE name = 'SocialMediaDB'
    )
    BEGIN
    CREATE DATABASE SocialMediaDB
        ON
        (
            NAME = 'SocialMediaData',
            FILENAME = '/var/opt/mssql/data/SocialMediaData.mdf',
            SIZE = 10MB,
            MAXSIZE = 200MB,
            FILEGROWTH = 10MB
        )
        LOG ON
        (
            NAME = 'SocialMediaLog',
            FILENAME = '/var/opt/mssql/data/SocialMediaLog.ldf',
            SIZE = 10MB,
            MAXSIZE = 100MB,
            FILEGROWTH = 10MB
        );

    PRINT 'SocialMediaDB database created successfully.';
END
    ELSE
    BEGIN
    PRINT 'SocialMediaDB database already exists.';
END
END TRY
BEGIN CATCH
    PRINT 'An error occurred while creating the database.';
    PRINT ERROR_MESSAGE();
END CATCH;
GO

USE SocialMediaDB;
GO

BEGIN TRANSACTION;

CREATE TABLE Audit
(
    Id uniqueidentifier NOT NULL,
    TableName nvarchar(128) NOT NULL,
    FieldName nvarchar(128) NOT NULL,
    RecordId uniqueidentifier NOT NULL,
    OldValue nvarchar(max) NOT NULL,
    NewValue nvarchar(max) NOT NULL,
    Action nvarchar(max) NOT NULL,
    PerformerId uniqueidentifier NOT NULL,
    PerformerIp nvarchar(64) NOT NULL,
    PerformedAt datetime2 NOT NULL,
    CONSTRAINT PK_Audit PRIMARY KEY (Id)
);

CREATE TABLE Chat
(
    Id uniqueidentifier NOT NULL,
    Name nvarchar(50) NOT NULL,
    Description nvarchar(500) NULL,
    ImageData nvarchar(max) NULL,
    IsGroupChat bit NOT NULL,
    CONSTRAINT PK_Chat PRIMARY KEY (Id)
);

CREATE TABLE ChatParticipantRole
(
    Id uniqueidentifier NOT NULL,
    Name nvarchar(50) NOT NULL UNIQUE,
    Description nvarchar(200) NOT NULL,
    CONSTRAINT PK_ChatParticipantRole PRIMARY KEY (Id)
);

CREATE TABLE RefreshTokens
(
    Id uniqueidentifier NOT NULL,
    Token nvarchar(172) NOT NULL UNIQUE,
    TokenExpiryTime datetime2 NOT NULL,
    UserId uniqueidentifier NOT NULL UNIQUE,
    CONSTRAINT PK_RefreshTokens PRIMARY KEY (Id)
);

CREATE TABLE UserRole
(
    Id uniqueidentifier NOT NULL,
    Name nvarchar(50) NOT NULL UNIQUE,
    Description nvarchar(200) NOT NULL,
    CONSTRAINT PK_UserRole PRIMARY KEY (Id)
);

CREATE TABLE Users
(
    Id uniqueidentifier NOT NULL,
    Login nvarchar(50) NOT NULL UNIQUE,
    PasswordHash nvarchar(128) NOT NULL,
    Email nvarchar(100) NOT NULL UNIQUE,
    FirstName nvarchar(50) NOT NULL,
    LastName nvarchar(50) NOT NULL,
    Bio nvarchar(500) NOT NULL,
    ProfileImageData nvarchar(max) NULL,
    RoleId uniqueidentifier NOT NULL,
    RefreshTokenId uniqueidentifier NOT NULL UNIQUE,
    CONSTRAINT PK_Users PRIMARY KEY (Id),
    CONSTRAINT FK_Users_RefreshTokens_RefreshTokenId FOREIGN KEY (RefreshTokenId) REFERENCES RefreshTokens (Id) ON DELETE CASCADE,
    CONSTRAINT FK_Users_UserRole_RoleId FOREIGN KEY (RoleId) REFERENCES UserRole (Id) ON DELETE CASCADE
);

CREATE TABLE ChatParticipant
(
    Id uniqueidentifier NOT NULL,
    ChatId uniqueidentifier NOT NULL,
    UserId uniqueidentifier NOT NULL,
    RoleId uniqueidentifier NOT NULL,
    CONSTRAINT PK_ChatParticipant PRIMARY KEY (Id),
    CONSTRAINT FK_ChatParticipant_ChatParticipantRole_RoleId FOREIGN KEY (RoleId) REFERENCES ChatParticipantRole (Id) ON DELETE CASCADE,
    CONSTRAINT FK_ChatParticipant_Chat_ChatId FOREIGN KEY (ChatId) REFERENCES Chat (Id) ON DELETE CASCADE,
    CONSTRAINT FK_ChatParticipant_Users_UserId FOREIGN KEY (UserId) REFERENCES Users (Id) ON DELETE CASCADE
);

CREATE TABLE Follows
(
    Id uniqueidentifier NOT NULL,
    UserId uniqueidentifier NOT NULL,
    FollowedUserId uniqueidentifier NOT NULL,
    CONSTRAINT PK_Follows PRIMARY KEY (Id),
    CONSTRAINT FK_Follows_Users_FollowedUserId FOREIGN KEY (FollowedUserId) REFERENCES Users (Id),
    CONSTRAINT FK_Follows_Users_UserId FOREIGN KEY (UserId) REFERENCES Users (Id)
);

CREATE TABLE Message
(
    Id uniqueidentifier NOT NULL,
    Text nvarchar(500) NOT NULL,
    AttachedImageData nvarchar(max) NOT NULL,
    SendDateTime datetime2 NOT NULL,
    ChatId uniqueidentifier NOT NULL,
    SenderId uniqueidentifier NOT NULL,
    ReplyToMessageId uniqueidentifier NULL,
    CONSTRAINT PK_Message PRIMARY KEY (Id),
    CONSTRAINT FK_Message_Chat_ChatId FOREIGN KEY (ChatId) REFERENCES Chat (Id),
    CONSTRAINT FK_Message_Message_ReplyToMessageId FOREIGN KEY (ReplyToMessageId) REFERENCES Message (Id),
    CONSTRAINT FK_Message_Users_SenderId FOREIGN KEY (SenderId) REFERENCES Users (Id)
);

CREATE TABLE Publications
(
    Id uniqueidentifier NOT NULL,
    Description nvarchar(1000) NOT NULL,
    ImageData nvarchar(max) NULL,
    CreationDateTime datetime2 NOT NULL,
    CreatorId uniqueidentifier NOT NULL,
    CONSTRAINT PK_Publications PRIMARY KEY (Id),
    CONSTRAINT FK_Publications_Users_CreatorId FOREIGN KEY (CreatorId) REFERENCES Users (Id) ON DELETE CASCADE
);

CREATE TABLE Report
(
    Id uniqueidentifier NOT NULL,
    ReporterId uniqueidentifier NOT NULL,
    TargetType nvarchar(50) NOT NULL,
    TargetId uniqueidentifier NOT NULL,
    Reason nvarchar(1000) NOT NULL,
    CreatedAt datetime2 NOT NULL,
    Resolved bit NOT NULL DEFAULT CAST(0 AS bit),
    ResolvedById uniqueidentifier NULL,
    ResolutionComment nvarchar(1000) NULL,
    ResolvedAt datetime2 NULL,
    CONSTRAINT PK_Report PRIMARY KEY (Id),
    CONSTRAINT FK_Report_Users_ReporterId FOREIGN KEY (ReporterId) REFERENCES Users (Id) ON DELETE CASCADE,
    CONSTRAINT FK_Report_Users_ResolvedById FOREIGN KEY (ResolvedById) REFERENCES Users (Id)
);

CREATE TABLE UserRestriction
(
    Id uniqueidentifier NOT NULL,
    TargetUserId uniqueidentifier NOT NULL UNIQUE,
    ImposedByUserId uniqueidentifier NOT NULL,
    Type nvarchar(450) NOT NULL,
    Reason nvarchar(500) NOT NULL,
    StartAt datetime2 NOT NULL,
    EndAt datetime2 NULL,
    CONSTRAINT PK_UserRestriction PRIMARY KEY (Id),
    CONSTRAINT FK_UserRestriction_Users_ImposedByUserId FOREIGN KEY (ImposedByUserId) REFERENCES Users (Id) ON DELETE CASCADE,
    CONSTRAINT FK_UserRestriction_Users_TargetUserId FOREIGN KEY (TargetUserId) REFERENCES Users (Id)
);

CREATE TABLE MessageLike
(
    Id uniqueidentifier NOT NULL,
    MessageId uniqueidentifier NOT NULL,
    UserId uniqueidentifier NOT NULL,
    CONSTRAINT PK_MessageLike PRIMARY KEY (Id),
    CONSTRAINT FK_MessageLike_Message_MessageId FOREIGN KEY (MessageId) REFERENCES Message (Id) ON DELETE CASCADE,
    CONSTRAINT FK_MessageLike_Users_UserId FOREIGN KEY (UserId) REFERENCES Users (Id) ON DELETE CASCADE
);

CREATE TABLE Comments
(
    Id uniqueidentifier NOT NULL,
    Description nvarchar(500) NOT NULL,
    CreationDateTime datetime2 NOT NULL,
    CreatorId uniqueidentifier NOT NULL,
    RelatedPublicationId uniqueidentifier NOT NULL,
    ReplyToCommentId uniqueidentifier NULL,
    CONSTRAINT PK_Comments PRIMARY KEY (Id),
    CONSTRAINT FK_Comments_Comments_ReplyToCommentId FOREIGN KEY (ReplyToCommentId) REFERENCES Comments (Id),
    CONSTRAINT FK_Comments_Publications_RelatedPublicationId FOREIGN KEY (RelatedPublicationId) REFERENCES Publications (Id),
    CONSTRAINT FK_Comments_Users_CreatorId FOREIGN KEY (CreatorId) REFERENCES Users (Id)
);

CREATE TABLE PublicationLikes
(
    Id uniqueidentifier NOT NULL,
    UserId uniqueidentifier NOT NULL,
    PublicationId uniqueidentifier NOT NULL,
    CONSTRAINT PK_PublicationLikes PRIMARY KEY (Id),
    CONSTRAINT FK_PublicationLikes_Publications_PublicationId FOREIGN KEY (PublicationId) REFERENCES Publications (Id),
    CONSTRAINT FK_PublicationLikes_Users_UserId FOREIGN KEY (UserId) REFERENCES Users (Id)
);

CREATE TABLE CommentLikes
(
    Id uniqueidentifier NOT NULL,
    UserId uniqueidentifier NOT NULL,
    CommentId uniqueidentifier NOT NULL,
    CONSTRAINT PK_CommentLikes PRIMARY KEY (Id),
    CONSTRAINT FK_CommentLikes_Comments_CommentId FOREIGN KEY (CommentId) REFERENCES Comments (Id),
    CONSTRAINT FK_CommentLikes_Users_UserId FOREIGN KEY (UserId) REFERENCES Users (Id)
);

COMMIT;
GO


/*
================================================================================
  START OF DATABASE POPULATION SECTION
  This part is dedicated to inserting initial data into the database:
  - Populating tables with sample or production records
  - Inserting lookup/reference data essential for application logic
  - Setting up default values and seed data required for testing or usage
  Ensure that the database schema is fully created before running these inserts.
================================================================================
*/

BEGIN TRANSACTION;

-- Insert User Roles
INSERT INTO UserRole
    (Id, Name, Description)
VALUES
    ('5fe0adee-241f-44d5-837f-745980dabe1f', 'Admin', 'System administrator with full access'),
    ('0521f037-cc26-4b00-bfa0-9c2024dff44a', 'Moderator', 'Content moderator with elevated privileges'),
    ('05c1482a-4545-4897-9763-6615288b749d', 'User', 'Regular user with standard privileges');

-- Insert Chat Participant Roles
INSERT INTO ChatParticipantRole
    (Id, Name, Description)
VALUES
    ('43136e09-7471-46f8-8ea5-7b2aebe69c65', 'Owner', 'Chat owner with full control'),
    ('e886bdde-c946-4890-baa5-5cf922b8ec90', 'Admin', 'Chat administrator'),
    ('2024a31e-b777-41e5-a806-52a3514c19f7', 'Member', 'Regular chat member');

-- Insert Refresh Tokens
INSERT INTO RefreshTokens
    (Id, Token, TokenExpiryTime, UserId)
VALUES
    ('da30d60d-3a69-4967-968b-03e6ec150d66', 'refresh_token_john_doe_12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890', DATEADD(day, 30, GETDATE()), '92af4681-020b-4925-aed8-4e2d195216e3'),
    ('23b55817-cd7f-4493-80ab-3ab8e0c5a9d1', 'refresh_token_jane_smith_123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678', DATEADD(day, 30, GETDATE()), 'a90de1dc-b51c-4373-acc7-a8ae5f749504'),
    ('26ad09ac-beb2-4933-a1ed-9fa177906a80', 'refresh_token_mike_johnson_1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456', DATEADD(day, 30, GETDATE()), '480b33ae-5d7d-4e54-8c04-f3f6ca251160'),
    ('5a6ea0d8-ce5a-4205-bf34-8675c32c409f', 'refresh_token_emily_davis_123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345', DATEADD(day, 30, GETDATE()), 'db6466f4-0ece-4ce4-ae9e-0d70639f9d80'),
    ('b18b47b8-6480-4ccd-a5a1-2429bfd1a1c7', 'refresh_token_alex_wilson_123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345', DATEADD(day, 30, GETDATE()), '3f9d2652-aff1-425f-85f6-b5213b728b7d'),
    ('e0bf7087-45f3-4fa7-a13f-f734efa7d017', 'refresh_token_sarah_brown_12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567', DATEADD(day, 30, GETDATE()), 'e886bdde-c946-4890-baa5-5cf922b8ec90');

-- Insert Users
INSERT INTO Users
    (Id, Login, PasswordHash, Email, FirstName, LastName, Bio, ProfileImageData, RoleId, RefreshTokenId)
VALUES
    ('92af4681-020b-4925-aed8-4e2d195216e3', 'johndoe', 'hashed_password_john_123456789012345678901234567890123456789012345678901234567890123456789012345678901234567', 'john.doe@email.com', 'John', 'Doe', 'Software developer passionate about technology and innovation. Love coding and sharing knowledge with the community.', 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD...', '5fe0adee-241f-44d5-837f-745980dabe1f', 'da30d60d-3a69-4967-968b-03e6ec150d66'),
    ('a90de1dc-b51c-4373-acc7-a8ae5f749504', 'janesmith', 'hashed_password_jane_123456789012345678901234567890123456789012345678901234567890123456789012345678901234567', 'jane.smith@email.com', 'Jane', 'Smith', 'Digital marketing specialist and content creator. Helping brands tell their story through engaging content.', NULL, '0521f037-cc26-4b00-bfa0-9c2024dff44a', '23b55817-cd7f-4493-80ab-3ab8e0c5a9d1'),
    ('480b33ae-5d7d-4e54-8c04-f3f6ca251160', 'mikejohnson', 'hashed_password_mike_123456789012345678901234567890123456789012345678901234567890123456789012345678901234567', 'mike.johnson@email.com', 'Mike', 'Johnson', 'Photographer and travel enthusiast. Capturing moments and sharing adventures from around the world.', 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD...', '05c1482a-4545-4897-9763-6615288b749d', '26ad09ac-beb2-4933-a1ed-9fa177906a80'),
    ('db6466f4-0ece-4ce4-ae9e-0d70639f9d80', 'emilydavis', 'hashed_password_emily_12345678901234567890123456789012345678901234567890123456789012345678901234567890123456', 'emily.davis@email.com', 'Emily', 'Davis', 'Fitness coach and wellness advocate. Helping people achieve their health goals through sustainable lifestyle changes.', NULL, '05c1482a-4545-4897-9763-6615288b749d', '5a6ea0d8-ce5a-4205-bf34-8675c32c409f'),
    ('3f9d2652-aff1-425f-85f6-b5213b728b7d', 'alexwilson', 'hashed_password_alex_123456789012345678901234567890123456789012345678901234567890123456789012345678901234567', 'alex.wilson@email.com', 'Alex', 'Wilson', 'Musician and music producer. Creating beats and melodies that inspire and connect people through the power of music.', 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD...', '05c1482a-4545-4897-9763-6615288b749d', 'b18b47b8-6480-4ccd-a5a1-2429bfd1a1c7'),
    ('e886bdde-c946-4890-baa5-5cf922b8ec90', 'sarahbrown', 'hashed_password_sarah_12345678901234567890123456789012345678901234567890123456789012345678901234567890123456', 'sarah.brown@email.com', 'Sarah', 'Brown', 'Food blogger and chef. Sharing delicious recipes and culinary adventures from my kitchen to yours.', NULL, '05c1482a-4545-4897-9763-6615288b749d', 'e0bf7087-45f3-4fa7-a13f-f734efa7d017');

-- Insert Follows (User relationships)
INSERT INTO Follows
    (Id, UserId, FollowedUserId)
VALUES
    ('da30d60d-3a69-4967-968b-03e6ec150d66', '92af4681-020b-4925-aed8-4e2d195216e3', 'a90de1dc-b51c-4373-acc7-a8ae5f749504'),
    ('23b55817-cd7f-4493-80ab-3ab8e0c5a9d1', '92af4681-020b-4925-aed8-4e2d195216e3', '480b33ae-5d7d-4e54-8c04-f3f6ca251160'),
    ('26ad09ac-beb2-4933-a1ed-9fa177906a80', 'a90de1dc-b51c-4373-acc7-a8ae5f749504', '92af4681-020b-4925-aed8-4e2d195216e3'),
    ('5a6ea0d8-ce5a-4205-bf34-8675c32c409f', 'a90de1dc-b51c-4373-acc7-a8ae5f749504', 'db6466f4-0ece-4ce4-ae9e-0d70639f9d80'),
    ('b18b47b8-6480-4ccd-a5a1-2429bfd1a1c7', '480b33ae-5d7d-4e54-8c04-f3f6ca251160', '3f9d2652-aff1-425f-85f6-b5213b728b7d'),
    ('e0bf7087-45f3-4fa7-a13f-f734efa7d017', 'db6466f4-0ece-4ce4-ae9e-0d70639f9d80', 'e886bdde-c946-4890-baa5-5cf922b8ec90'),
    ('f490af98-30f9-476c-9906-7601421f859c', '3f9d2652-aff1-425f-85f6-b5213b728b7d', '92af4681-020b-4925-aed8-4e2d195216e3'),
    ('f2428c9f-5693-42f5-886c-ad33c9b8dab3', 'e886bdde-c946-4890-baa5-5cf922b8ec90', 'a90de1dc-b51c-4373-acc7-a8ae5f749504');

-- Insert Publications with updated IDs
INSERT INTO Publications
    (Id, Description, CreationDateTime, CreatorId)
VALUES
    ('7a70d255-55b1-428d-8fa7-378ca8e2e8b8', 'Just finished working on a new web application using React and Node.js. The learning curve was steep but totally worth it! 🚀 #coding #webdev', DATEADD(hour, -2, GETDATE()), '92af4681-020b-4925-aed8-4e2d195216e3'),
    ('128ede1e-a83f-405f-be30-73b69bf05483', 'Content marketing tip: Authenticity beats perfection every time. Your audience wants to connect with real stories, not polished facades. ✨', DATEADD(hour, -4, GETDATE()), 'a90de1dc-b51c-4373-acc7-a8ae5f749504'),
    ('bdb082e4-81ed-4696-9985-47ee08a04d61', 'Captured this amazing sunset during my hike in the mountains yesterday. Nature never fails to inspire! 🏔️📸', DATEADD(day, -1, GETDATE()), '480b33ae-5d7d-4e54-8c04-f3f6ca251160'),
    ('193880b7-e34a-4e20-b1ae-31c6b4e64d7c', 'Remember: Small consistent actions lead to big results. Whether its fitness, career, or personal growth - consistency is key! 💪', DATEADD(hour, -6, GETDATE()), 'db6466f4-0ece-4ce4-ae9e-0d70639f9d80'),
    ('daeac86f-90ae-42af-b5b5-76739f5a8042', 'Working on a new track that blends electronic and acoustic elements. Music is the universal language that connects us all 🎵🎹', DATEADD(hour, -8, GETDATE()), '3f9d2652-aff1-425f-85f6-b5213b728b7d'),
    ('87f34205-aa9a-495f-9b82-81cc359cc65b', 'Just tried making homemade pasta for the first time! The process is therapeutic and the taste is incredible. Recipe coming soon! 🍝👩‍🍳', DATEADD(hour, -10, GETDATE()), 'e886bdde-c946-4890-baa5-5cf922b8ec90');

-- Insert Publication Likes
INSERT INTO PublicationLikes
    (Id, UserId, PublicationId)
VALUES
    ('3722d616-1284-44fc-8165-2f7d1d0f9caf', 'a90de1dc-b51c-4373-acc7-a8ae5f749504', '7a70d255-55b1-428d-8fa7-378ca8e2e8b8'),
    ('36c1763b-8ec8-4225-a679-c4bfd216b0ba', '480b33ae-5d7d-4e54-8c04-f3f6ca251160', '7a70d255-55b1-428d-8fa7-378ca8e2e8b8'),
    ('b129102b-2740-4fe0-95c8-dc1f1685adeb', '92af4681-020b-4925-aed8-4e2d195216e3', '128ede1e-a83f-405f-be30-73b69bf05483'),
    ('e1ef921c-1b67-4c3a-97ab-69128ea3da12', 'db6466f4-0ece-4ce4-ae9e-0d70639f9d80', '128ede1e-a83f-405f-be30-73b69bf05483'),
    ('fd12988f-874c-49cb-bfb1-34a843db8c37', '3f9d2652-aff1-425f-85f6-b5213b728b7d', 'bdb082e4-81ed-4696-9985-47ee08a04d61'),
    ('310fb95d-6326-456b-8b72-9f60dbc0370f', 'e886bdde-c946-4890-baa5-5cf922b8ec90', '193880b7-e34a-4e20-b1ae-31c6b4e64d7c');

-- Insert Comments
INSERT INTO Comments
    (Id, Description, CreationDateTime, CreatorId, RelatedPublicationId, ReplyToCommentId)
VALUES
    ('8ad762d6-8b1e-4e08-8b1b-7106b08108a6', 'Great work! React and Node.js is such a powerful combination. What kind of features did you implement?', DATEADD(hour, -1, GETDATE()), 'a90de1dc-b51c-4373-acc7-a8ae5f749504', '7a70d255-55b1-428d-8fa7-378ca8e2e8b8', NULL),
    ('fb4eb957-c258-48b2-9e83-cf0428f2e178', 'Thanks! I built a real-time chat application with authentication and file sharing capabilities.', DATEADD(minute, -45, GETDATE()), '92af4681-020b-4925-aed8-4e2d195216e3', '7a70d255-55b1-428d-8fa7-378ca8e2e8b8', '8ad762d6-8b1e-4e08-8b1b-7106b08108a6'),
    ('57c28bc0-38de-4cd5-a37c-a6871ba879d1', 'So true! Authentic content always resonates better with audiences.', DATEADD(hour, -3, GETDATE()), '92af4681-020b-4925-aed8-4e2d195216e3', '128ede1e-a83f-405f-be30-73b69bf05483', NULL),
    ('e930ea97-8b26-437b-8fda-c91d8737f963', 'Absolutely stunning photo! Where was this taken?', DATEADD(hour, -20, GETDATE()), '3f9d2652-aff1-425f-85f6-b5213b728b7d', 'bdb082e4-81ed-4696-9985-47ee08a04d61', NULL),
    ('b23a0449-b3d8-4afa-8068-9e22792ff7c2', 'This was at Rocky Mountain National Park in Colorado. Highly recommend visiting!', DATEADD(hour, -19, GETDATE()), '480b33ae-5d7d-4e54-8c04-f3f6ca251160', 'bdb082e4-81ed-4696-9985-47ee08a04d61', 'e930ea97-8b26-437b-8fda-c91d8737f963'),
    ('a783e72c-ba23-45fd-9f84-a307d22ac070', 'Love this message! Consistency really is everything. Thanks for the motivation! 🙌', DATEADD(hour, -5, GETDATE()), 'e886bdde-c946-4890-baa5-5cf922b8ec90', '193880b7-e34a-4e20-b1ae-31c6b4e64d7c', NULL);

-- Insert Comment Likes
INSERT INTO CommentLikes
    (Id, UserId, CommentId)
VALUES
    ('b5af476a-4002-4f38-8994-522b6fc8a179', '92af4681-020b-4925-aed8-4e2d195216e3', '8ad762d6-8b1e-4e08-8b1b-7106b08108a6'),
    ('be3ba2df-4df9-49b3-86a1-9017ad486b1d', '480b33ae-5d7d-4e54-8c04-f3f6ca251160', '8ad762d6-8b1e-4e08-8b1b-7106b08108a6'),
    ('aea5c5ca-5fc1-4a50-82f6-189787dee5b1', 'a90de1dc-b51c-4373-acc7-a8ae5f749504', '57c28bc0-38de-4cd5-a37c-a6871ba879d1'),
    ('cbccd438-ebde-40c9-88bf-39ab22ee3df6', 'db6466f4-0ece-4ce4-ae9e-0d70639f9d80', 'a783e72c-ba23-45fd-9f84-a307d22ac070');

-- Insert Chats
INSERT INTO Chat
    (Id, Name, Description, ImageData, IsGroupChat)
VALUES
    ('c00bd6ca-588a-4913-9887-f8b097de70a7', 'Tech Talk', 'Discussion group for technology enthusiasts', NULL, 1),
    ('f0823196-50c5-4f89-8cc8-92531f3d3885', 'Photography Club', 'Share and discuss photography techniques and experiences', 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD...', 1),
    ('d2d375ed-a176-4452-8202-5addb31fc74d', '', 'Direct message conversation', NULL, 0),
    ('76db0c63-d3e7-4249-a249-2be316e94912', '', 'Direct message conversation', NULL, 0);

-- Insert Chat Participants
INSERT INTO ChatParticipant
    (Id, ChatId, UserId, RoleId)
VALUES
    ('d950ae60-647f-4acc-9f86-97f4e96769f5', 'c00bd6ca-588a-4913-9887-f8b097de70a7', '92af4681-020b-4925-aed8-4e2d195216e3', '43136e09-7471-46f8-8ea5-7b2aebe69c65'),
    ('3a24dc29-e47a-4c2c-b518-571462bf73d1', 'c00bd6ca-588a-4913-9887-f8b097de70a7', 'a90de1dc-b51c-4373-acc7-a8ae5f749504', '2024a31e-b777-41e5-a806-52a3514c19f7'),
    ('da19b80f-2eb6-4d3b-9ef7-bcbc25cd8823', 'c00bd6ca-588a-4913-9887-f8b097de70a7', '3f9d2652-aff1-425f-85f6-b5213b728b7d', '2024a31e-b777-41e5-a806-52a3514c19f7'),
    ('75bbc573-94d3-4255-9fda-5f3fba65fe08', 'f0823196-50c5-4f89-8cc8-92531f3d3885', '480b33ae-5d7d-4e54-8c04-f3f6ca251160', '43136e09-7471-46f8-8ea5-7b2aebe69c65'),
    ('288662c5-3be9-4b69-b6f2-5d6be16c73f7', 'f0823196-50c5-4f89-8cc8-92531f3d3885', '92af4681-020b-4925-aed8-4e2d195216e3', '2024a31e-b777-41e5-a806-52a3514c19f7'),
    ('adbaf4a4-77c5-4c9f-a661-a33d99ebdddd', 'd2d375ed-a176-4452-8202-5addb31fc74d', 'a90de1dc-b51c-4373-acc7-a8ae5f749504', '2024a31e-b777-41e5-a806-52a3514c19f7'),
    ('e203c46a-88a8-4fee-8e0a-4b000151af27', 'd2d375ed-a176-4452-8202-5addb31fc74d', 'db6466f4-0ece-4ce4-ae9e-0d70639f9d80', '2024a31e-b777-41e5-a806-52a3514c19f7'),
    ('44b483ac-6c96-4f4c-bf11-857870fa016c', '76db0c63-d3e7-4249-a249-2be316e94912', '3f9d2652-aff1-425f-85f6-b5213b728b7d', '2024a31e-b777-41e5-a806-52a3514c19f7'),
    ('a95c98b5-a4a1-49a2-9f1a-15c25cd6afaa', '76db0c63-d3e7-4249-a249-2be316e94912', 'e886bdde-c946-4890-baa5-5cf922b8ec90', '2024a31e-b777-41e5-a806-52a3514c19f7');

-- Insert Messages
INSERT INTO Message
    (Id, Text, AttachedImageData, SendDateTime, ChatId, SenderId, ReplyToMessageId)
VALUES
    ('668e34af-0e69-4a62-9957-e8392f4bcdec', 'Hey everyone! Welcome to our tech discussion group. Feel free to share any interesting articles or projects youre working on!', '', DATEADD(hour, -12, GETDATE()), 'c00bd6ca-588a-4913-9887-f8b097de70a7', '92af4681-020b-4925-aed8-4e2d195216e3', NULL),
    ('36c1763b-8ec8-4225-a679-c4bfd216b0ba', 'Thanks for creating this group! I just came across an interesting article about AI developments in healthcare. Should I share it here?', '', DATEADD(hour, -11, GETDATE()), 'c00bd6ca-588a-4913-9887-f8b097de70a7', 'a90de1dc-b51c-4373-acc7-a8ae5f749504', NULL),
    ('146f73cc-6762-496b-885a-49c3306cfe68', 'Absolutely! That sounds really interesting. Please share away!', '', DATEADD(hour, -10, GETDATE()), 'c00bd6ca-588a-4913-9887-f8b097de70a7', '92af4681-020b-4925-aed8-4e2d195216e3', '36c1763b-8ec8-4225-a679-c4bfd216b0ba'),
    ('6911f318-40f6-427e-a245-ae9e9ecfb639', 'I am working on a music production app that uses machine learning to suggest chord progressions. Its been quite a journey!', '', DATEADD(hour, -9, GETDATE()), 'c00bd6ca-588a-4913-9887-f8b097de70a7', '3f9d2652-aff1-425f-85f6-b5213b728b7d', NULL),
    ('a3b54676-e5bc-4752-bf0a-5b95c5e4e38c', 'Welcome to the Photography Club! Lets share our best shots and learn from each other.', '', DATEADD(hour, -8, GETDATE()), 'f0823196-50c5-4f89-8cc8-92531f3d3885', '480b33ae-5d7d-4e54-8c04-f3f6ca251160', NULL),
    ('b8c9e5ba-ca1c-44a3-8e63-f715a942dc98', 'Here is a landscape shot I took during golden hour last weekend', 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD...', DATEADD(hour, -7, GETDATE()), 'f0823196-50c5-4f89-8cc8-92531f3d3885', '92af4681-020b-4925-aed8-4e2d195216e3', NULL),
    ('2f1288e6-a41e-42e7-90bf-14d2c10cecec', 'Hi Jane! I saw your latest marketing post and found it really insightful. Would love to collaborate on some projects.', '', DATEADD(hour, -6, GETDATE()), 'd2d375ed-a176-4452-8202-5addb31fc74d', 'db6466f4-0ece-4ce4-ae9e-0d70639f9d80', NULL),
    ('7903b8e3-f4a2-4a37-a495-dac2c6e0c5e7', 'Hi Emily! Thank you so much! I would love to collaborate. What kind of projects did you have in mind?', '', DATEADD(hour, -5, GETDATE()), 'd2d375ed-a176-4452-8202-5addb31fc74d', 'a90de1dc-b51c-4373-acc7-a8ae5f749504', NULL),
    ('ce41589c-1858-40c6-bd1c-a1112792a938', 'Hey Alex! Loved your latest track. The blend of electronic and acoustic is amazing. Any tips for a beginner producer?', '', DATEADD(hour, -4, GETDATE()), '76db0c63-d3e7-4249-a249-2be316e94912', 'e886bdde-c946-4890-baa5-5cf922b8ec90', NULL),
    ('a5ac73dd-8c8b-4127-aee7-9e43ad0d2ea8', 'Thanks Sarah! My advice would be to start simple and focus on learning one DAW really well. Also, dont be afraid to experiment!', '', DATEADD(hour, -3, GETDATE()), '76db0c63-d3e7-4249-a249-2be316e94912', '3f9d2652-aff1-425f-85f6-b5213b728b7d', 'ce41589c-1858-40c6-bd1c-a1112792a938');

-- Insert Message Likes
INSERT INTO MessageLike
    (Id, MessageId, UserId)
VALUES
    ('6f6fe0ba-15eb-4368-b53f-a512b41bee43', '668e34af-0e69-4a62-9957-e8392f4bcdec', 'a90de1dc-b51c-4373-acc7-a8ae5f749504'),
    ('980fb84e-0858-4808-87c1-b974c5ad51c1', '668e34af-0e69-4a62-9957-e8392f4bcdec', '3f9d2652-aff1-425f-85f6-b5213b728b7d'),
    ('aef5dfdd-f24e-41e8-91c7-a362bc3773bc', '6911f318-40f6-427e-a245-ae9e9ecfb639', '92af4681-020b-4925-aed8-4e2d195216e3'),
    ('b92b7244-3a75-4496-8494-b1f65e429e3e', 'b8c9e5ba-ca1c-44a3-8e63-f715a942dc98', '480b33ae-5d7d-4e54-8c04-f3f6ca251160'),
    ('82c10ee4-7a70-403c-864f-493b62edd94e', 'a5ac73dd-8c8b-4127-aee7-9e43ad0d2ea8', 'e886bdde-c946-4890-baa5-5cf922b8ec90');

-- Insert Reports
INSERT INTO Report
    (Id, ReporterId, TargetType, TargetId, Reason, CreatedAt, Resolved, ResolvedById, ResolutionComment, ResolvedAt)
VALUES
    ('6038d926-f9a8-479e-96b9-bf30216304df', 'db6466f4-0ece-4ce4-ae9e-0d70639f9d80', 'Publication', '128ede1e-a83f-405f-be30-73b69bf05483', 'Suspected spam content - posting similar messages repeatedly', DATEADD(day, -2, GETDATE()), 1, 'a90de1dc-b51c-4373-acc7-a8ae5f749504', 'Reviewed content - not spam, legitimate music promotion. No action taken.', DATEADD(day, -1, GETDATE())),
    ('f37ef50b-a7ad-4218-898a-f315ca0319a2', 'e886bdde-c946-4890-baa5-5cf922b8ec90', 'Comment', 'fb4eb957-c258-48b2-9e83-cf0428f2e178', 'Inappropriate language used in comment thread', DATEADD(hour, -6, GETDATE()), 0, NULL, NULL, NULL);

-- Insert User Restrictions
INSERT INTO UserRestriction
    (Id, TargetUserId, ImposedByUserId, Type, Reason, StartAt, EndAt)
VALUES
    ('829aac3a-d959-4b47-8e0e-5d7cf121de0c', '3f9d2652-aff1-425f-85f6-b5213b728b7d', 'a90de1dc-b51c-4373-acc7-a8ae5f749504', 'TemporaryMute', 'Excessive self-promotion without engaging with community', DATEADD(day, -1, GETDATE()), DATEADD(day, 2, GETDATE()));

-- Insert Audit Records
INSERT INTO Audit
    (Id, TableName, FieldName, RecordId, OldValue, NewValue, Action, PerformerId, PerformerIp, PerformedAt)
VALUES
    ('4dd87efc-27c0-41ce-8536-97907913361d', 'Users', 'Bio', '92af4681-020b-4925-aed8-4e2d195216e3', 'Software developer passionate about technology.', 'Software developer passionate about technology and innovation. Love coding and sharing knowledge with the community.', 'UPDATE', '92af4681-020b-4925-aed8-4e2d195216e3', '192.168.1.100', DATEADD(day, -3, GETDATE())),
    ('bee418ee-7453-4237-98cd-32e7d301ae0e', 'Publications', 'Description', '7a70d255-55b1-428d-8fa7-378ca8e2e8b8', '', 'Just finished working on a new web application using React and Node.js. The learning curve was steep but totally worth it! 🚀 #coding #webdev', 'INSERT', '92af4681-020b-4925-aed8-4e2d195216e3', '192.168.1.100', DATEADD(hour, -2, GETDATE())),
    ('2ee4e614-578f-4ec1-94a1-681b89e12401', 'Report', 'Resolved', '6038d926-f9a8-479e-96b9-bf30216304df', '0', '1', 'UPDATE', 'a90de1dc-b51c-4373-acc7-a8ae5f749504', '192.168.1.101', DATEADD(day, -1, GETDATE())),
    ('5b06b110-7459-4762-95c7-27952b0cbc5b', 'UserRestriction', 'Type', '829aac3a-d959-4b47-8e0e-5d7cf121de0c', '', 'TemporaryMute', 'INSERT', 'a90de1dc-b51c-4373-acc7-a8ae5f749504', '192.168.1.101', DATEADD(day, -1, GETDATE()));

COMMIT;
GO