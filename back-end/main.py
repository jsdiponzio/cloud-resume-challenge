from google.cloud import firestore

#increment function
def increment_fetch(request, test=False):
    if not test:
        db = firestore.Client(project='jess-cloud-resume-challenge')
    else:
        db = test
    doc_ref = db.collection(u'site-views').document(u'visitors')
    doc = doc_ref.get()
    count = doc.to_dict()['VisitorCount']

    updated_count = count + 1
    doc_ref.update({u'VisitorCount': updated_count})

    headers = {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json'
    }
    return (f"{updated_count}", 200, headers)

increment_fetch("{}")