class AddMediaToTrnWhatsappInbox < ActiveRecord::Migration[7.1]
  TABLE = :trn_whatsapp_inbox

  def up
    # Meta's webhook hands over a media ID, not a file and not a URL. To show a
    # photo the app has to exchange that ID for a short-lived signed URL and
    # then fetch it with the access token. None of that was being kept, so
    # every image, video, document and sticker arrived as an empty bubble.
    add_column TABLE, :wi_media_id,   :string, limit: 200 unless column_exists?(TABLE, :wi_media_id)
    add_column TABLE, :wi_media_mime, :string, limit: 100 unless column_exists?(TABLE, :wi_media_mime)
    add_column TABLE, :wi_media_name, :string, limit: 255 unless column_exists?(TABLE, :wi_media_name)
  end

  def down
    remove_column TABLE, :wi_media_id   if column_exists?(TABLE, :wi_media_id)
    remove_column TABLE, :wi_media_mime if column_exists?(TABLE, :wi_media_mime)
    remove_column TABLE, :wi_media_name if column_exists?(TABLE, :wi_media_name)
  end
end
