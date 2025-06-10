defprotocol Smalltalk.UuidDatable do
  def extract_and_format_timestamp(t, format \\ :default)
end

defimpl Smalltalk.UuidDatable, for: BitString do
  def extract_and_format_timestamp(string, :default) do
    string
    |> Ash.UUIDv7.extract_timestamp()
    |> DateTime.from_unix!(:millisecond)
    |> Timex.format!("{Mshort} {D} {YYYY}, {h12}:{m}:{s} {AM} (UTC)")
  end
end
