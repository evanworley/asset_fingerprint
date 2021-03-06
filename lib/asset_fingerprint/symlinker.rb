module AssetFingerprint
  
  def self.generate_all_symlinks
    Asset.generate_all_symlinks
  end

  def self.remove_all_symlinks
    Asset.remove_all_symlinks
  end
  
  @@symlink_on_the_fly = true
  def self.symlink_on_the_fly=(value)
    @@symlink_on_the_fly = value
  end
  
  def self.symlink_on_the_fly?
    @@symlink_on_the_fly
  end
  
  class Symlinker
    
    @@symlinked = Set.new
    
    def self.symlink_on_the_fly(asset)
      return unless AssetFingerprint.symlink_on_the_fly?
      execute(asset)
    end
    
    def self.execute(asset)
      if asset.symlinkable? && !already_symlinked?(asset.fingerprinted_path)

        # Make any missing parent directories
        FileUtils.mkdir_p(File.dirname(asset.fingerprinted_absolute_path))

        FileUtils.ln_sf(asset.source_absolute_path, asset.fingerprinted_absolute_path)
        @@symlinked << asset.fingerprinted_path
      end
    end
    
    def self.already_symlinked?(fingerprinted_path)
      if AssetFingerprint.symlink_on_the_fly?  
        File.exists?(fingerprinted_path)
      else
        @@symlinked.include?(fingerprinted_path) 
      end
    end
    
  end
end
