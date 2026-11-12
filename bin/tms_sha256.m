function digest=tms_sha256(filename)
  fid=fopen(filename,'rb'); assert(fid>=0); bytes=fread(fid,Inf,'*uint8'); fclose(fid);
  if exist('OCTAVE_VERSION','builtin')
    digest=hash('sha256',char(bytes'));
  else
    md=java.security.MessageDigest.getInstance('SHA-256'); md.update(bytes);
    digest=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2)',1,[]));
  end
end
