import brotli, sys, os
src, dst = sys.argv[1], sys.argv[2]
if os.path.exists(dst) and os.path.getsize(dst) > 0:
    print('skip, exists')
else:
    with open(src,'rb') as f, open(dst,'wb') as o:
        d = brotli.Decompressor()
        while True:
            chunk = f.read(1024*1024)
            if not chunk: break
            o.write(d.process(chunk))
    print('done', os.path.getsize(dst))
