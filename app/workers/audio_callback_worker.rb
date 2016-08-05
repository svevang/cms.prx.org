class AudioCallbackWorker
  include Shoryuken::Worker

  class UnknownAudioTypeError < StandardError; end

  shoryuken_options queue: "#{ENV['RAILS_ENV']}_cms_audio_callback"

  def perform(_sqs_msg, job)
    audio = AudioFile.find(job['id'])
    audio.filename = job['name']
    audio.length = job['duration']
    audio.size = job['size']
    audio.bit_rate = (job['bitrate'] || 0) / 1000
    audio.frequency = (job['frequency'] || 0) / 1000.0

    # decode content type and mpeg layer from basic "format" string
    mime_types = MIME::Types.type_for(job['format']).map(&:to_s)
    prefer_type = mime_types.find { |t| t.starts_with?('audio') }
    audio.content_type = prefer_type || mime_types.first || job['format']

    # get layer from mp2/3/4 format string
    audio.layer = (job['format'] || '').match(/mp(\d)/).try(:[], 1).to_i

    # TODO: not quite sure how to get this from ffprobe
    # job['channels'] = ffmpeg.channels
    # job['layout'] = ffmpeg.channel_layout
    if job['channels'] == 2
      audio.channel_mode = AudioFile::STEREO
    elsif job['channels'] == 1
      audio.channel_mode = AudioFile::SINGLE_CHANNEL
    else
      audio.channel_mode = nil
    end

    if !job['downloaded']
      audio.status = AudioFile::NOTFOUND
    elsif !job['valid']
      audio.status = AudioFile::INVALID
    elsif !job['processed']
      audio.status = AudioFile::FAILED
    else
      audio.upload_path = nil
      audio.status = AudioFile::COMPLETE
    end

    Shoryuken.logger.info("Updating #{job['type']}[#{audio.id}]: status => #{audio.status}")
    audio.save!
  rescue ActiveRecord::RecordNotFound
    Shoryuken.logger.error("Record #{job['type']}[#{job['id']}] not found")
  end

end
