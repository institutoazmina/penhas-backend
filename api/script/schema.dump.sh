#!/bin/bash -e
GIT_DIR=$(git rev-parse --show-toplevel)
CWD=$(pwd)
if [ -f envfile_local.sh ]; then
    source envfile_local.sh
else
    source envfile.sh
fi

cd $GIT_DIR/api/

dbicdump -o dump_directory=./lib \
             -Ilib \
             -o use_moose=0 \
             -o 'overwrite_modifications'=1 \
             -o 'generate_pod'=0 \
             -o result_base_class='Penhas::Schema::Base' \
             -o db_schema=public \
             -o filter_generated_code='sub {my ( $type, $class, $text ) = @_; return "#<<<\n$text#>>>"; }' \
             Penhas::Schema \
             "dbi:Pg:dbname=${POSTGRESQL_DBNAME};host=${POSTGRESQL_HOST};port=${POSTGRESQL_PORT}" $POSTGRESQL_USER $POSTGRESQL_PASSWORD


rm lib/Penhas/Schema/Result/DomainAllows.pm
rm lib/Penhas/Schema/Result/Tag.pm
rm lib/Penhas/Schema/Result/AdminActionLog.pm
rm lib/Penhas/Schema/Result/Status.pm
rm lib/Penhas/Schema/Result/SessionActivation.pm
rm lib/Penhas/Schema/Result/CustomEmojiCategory.pm
rm lib/Penhas/Schema/Result/AccountDomainBlock.pm
rm lib/Penhas/Schema/Result/SiteUpload.pm
rm lib/Penhas/Schema/Result/AccountWarning.pm
rm lib/Penhas/Schema/Result/Favourite.pm
rm lib/Penhas/Schema/Result/Follow.pm
rm lib/Penhas/Schema/Result/EmailDomainBlock.pm
rm lib/Penhas/Schema/Result/AccountPin.pm
rm lib/Penhas/Schema/Result/ListAccount.pm
rm lib/Penhas/Schema/Result/Mute.pm
rm lib/Penhas/Schema/Result/AccountConversation.pm
rm lib/Penhas/Schema/Result/AccountMigration.pm
rm lib/Penhas/Schema/Result/WebPushSubscription.pm
rm lib/Penhas/Schema/Result/ReportNote.pm
rm lib/Penhas/Schema/Result/Setting.pm
rm lib/Penhas/Schema/Result/Notification.pm
rm lib/Penhas/Schema/Result/Marker.pm
rm lib/Penhas/Schema/Result/CustomFilter.pm
rm lib/Penhas/Schema/Result/Tombstone.pm
rm lib/Penhas/Schema/Result/CustomEmoji.pm
rm lib/Penhas/Schema/Result/Block.pm
rm lib/Penhas/Schema/Result/Poll.pm
rm lib/Penhas/Schema/Result/ArInternalMetadata.pm
rm lib/Penhas/Schema/Result/Relay.pm
rm lib/Penhas/Schema/Result/FeaturedTag.pm
rm lib/Penhas/Schema/Result/SchemaMigration.pm
rm lib/Penhas/Schema/Result/Identity.pm
rm lib/Penhas/Schema/Result/DomainBlock.pm
rm lib/Penhas/Schema/Result/AccountStat.pm
rm lib/Penhas/Schema/Result/UserInviteRequest.pm
rm lib/Penhas/Schema/Result/AccountIdentityProof.pm
rm lib/Penhas/Schema/Result/ConversationMute.pm
rm lib/Penhas/Schema/Result/FollowRequest.pm
rm lib/Penhas/Schema/Result/AccountWarningPreset.pm
rm lib/Penhas/Schema/Result/Mention.pm
rm lib/Penhas/Schema/Result/AccountTagStat.pm
rm lib/Penhas/Schema/Result/Subscription.pm
rm lib/Penhas/Schema/Result/ScheduledStatus.pm
rm lib/Penhas/Schema/Result/Conversation.pm
rm lib/Penhas/Schema/Result/PgheroSpaceStat.pm
rm lib/Penhas/Schema/Result/OauthAccessGrant.pm
rm lib/Penhas/Schema/Result/StreamEntry.pm
rm lib/Penhas/Schema/Result/WebSetting.pm
rm lib/Penhas/Schema/Result/StatusStat.pm
rm lib/Penhas/Schema/Result/MediaAttachment.pm
rm lib/Penhas/Schema/Result/AccountsTag.pm
rm lib/Penhas/Schema/Result/Import.pm
rm lib/Penhas/Schema/Result/List.pm
rm lib/Penhas/Schema/Result/AccountModerationNote.pm
rm lib/Penhas/Schema/Result/Report.pm
rm lib/Penhas/Schema/Result/StatusPin.pm
rm lib/Penhas/Schema/Result/AccountAlias.pm
rm lib/Penhas/Schema/Result/PreviewCard.pm
rm lib/Penhas/Schema/Result/Invite.pm
rm lib/Penhas/Schema/Result/OauthApplication.pm
rm lib/Penhas/Schema/Result/Backup.pm
rm lib/Penhas/Schema/Result/PreviewCardsStatus.pm
rm lib/Penhas/Schema/Result/PollVote.pm
rm lib/Penhas/Schema/Result/StatusesTag.pm

cd $CWD
