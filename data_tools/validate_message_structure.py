import argparse
import json
import re

# Valdiates a message collection is of the form:
# https://github.com/AfricasVoices/CodaV2/blob/master/docs/data_formats.md

def verify_JSON_path(messages_path):
    f = open(messages_path, 'r')
    messages = json.loads(f.read())

    assert "messages" in messages.keys()
    messages = messages["messages"]
    assert isinstance(messages, list)

    seen_message_ids = set()

    for message in messages:
        assert isinstance(message, dict)

        assert "MessageID" in message.keys()
        MessageID = message["MessageID"]
        check_string(MessageID)
        assert MessageID not in seen_message_ids
        seen_message_ids.add(MessageID)

        assert "Text" in message.keys()
        Text = message["Text"]
        check_string(Text)

        assert "CreationDateTimeUTC" in message.keys()
        CreationDateTimeUTC = message["CreationDateTimeUTC"]
        check_iso8601_string(CreationDateTimeUTC)

        assert "Labels" in message.keys()
        Labels = message["Labels"]
        assert isinstance(Labels, list)

        for label in Labels:
            assert isinstance(label, dict)

            assert "SchemeID" in label.keys()
            SchemeID = label["SchemeID"]
            check_string(SchemeID)

            assert "CodeID" in label.keys()
            CodeID = label["CodeID"]
            check_string(CodeID)

            assert "DateTimeUTC" in label.keys()
            DateTimeUTC = label["DateTimeUTC"]
            check_iso8601_string(DateTimeUTC)

            if "Checked" in label.keys():
                check_bool(label["Checked"])

            if "Confidence" in label.keys():
                check_double(label["Confidence"])

            if "LabelSet" in label.keys():
                check_int(label["LabelSet"])

            assert "Origin" in label.keys()
            Origin = label["Origin"]
            assert isinstance(Origin, dict)

            assert "OriginID" in Origin.keys()
            OriginID = Origin["OriginID"]
            check_string(OriginID)

            assert "Name" in Origin.keys()
            Name = Origin["Name"]
            check_string(Name)

            assert "OriginType" in Origin.keys()
            OriginType = Origin["OriginType"]
            check_string(OriginType)

            assert "Metadata" in Origin.keys()
            Metadata = Origin["Metadata"]
            assert isinstance(Metadata, dict)

            for key, value in Metadata:
                check_string(key)
                check_string(value)

    return messages

def check_string(s):
    assert isinstance(s, unicode)
    assert s != ""

def check_int(i):
    assert isinstance(i, int)

def check_double(d):
    assert isinstance(d, float)

def check_bool(b):
    assert isinstance(b, bool)

# Regex from https://www.oreilly.com/library/view/regular-expressions-cookbook/9781449327453/ch04s07.html
iso8601_regex = r'^(-?(?:[1-9][0-9]*)?[0-9]{4})-(1[0-2]|0[1-9])-(3[01]|0[1-9]|[12][0-9])T(2[0-3]|[01][0-9]):([0-5][0-9]):([0-5][0-9])(\.[0-9]+)?(Z|[+-](?:2[0-3]|[01][0-9]):[0-5][0-9])?$'
match_iso8601 = re.compile(iso8601_regex).match

def check_iso8601_string(s):
    try:
        if match_iso8601(s) is not None:
            return True
    except:
        pass
    return False


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="verify messages collection")
    parser.add_argument("messages_path", help="Path to messages collection", nargs=1)

    args = parser.parse_args()
    MESSAGES_PATH = args.messages_path[0]

    verify_JSON_path(MESSAGES_PATH)
