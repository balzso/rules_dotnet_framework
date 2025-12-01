"""Path manipulation utilities

This module provides path manipulation utilities compatible with bazel-skylib's paths module.
It implements the minimal set of functions needed by rules_dotnet_framework to avoid
circular dependencies when using MODULE.bazel.
"""

def _basename(path):
    """Returns the basename (final component) of a path.
    
    Args:
        path: A path string
        
    Returns:
        The basename of the path
    """
    if not path:
        return ""
    
    # Normalize to forward slashes
    normalized = path.replace("\\", "/")
    
    # Remove trailing slashes using removesuffix (Bazel 5.0+)
    if normalized.endswith("/"):
        normalized = normalized.removesuffix("/")
    
    # Split and return last component
    parts = normalized.split("/")
    return parts[-1] if parts else ""

def _join(*components):
    """Joins path components with forward slashes.
    
    Args:
        *components: Path components to join
        
    Returns:
        The joined path
    """
    # Filter out empty components
    non_empty = [c for c in components if c]
    
    if not non_empty:
        return ""
    
    # Join with forward slashes and normalize multiple slashes
    result = "/".join(non_empty)
    
    # Normalize multiple slashes to single slash using replace in a loop
    for _ in range(10):  # Max 10 iterations to avoid infinite loops
        if "//" not in result:
            break
        result = result.replace("//", "/")
    
    return result

def _dirname(path):
    """Returns the directory portion of a path.
    
    Args:
        path: A path string
        
    Returns:
        The directory portion of the path
    """
    if not path:
        return ""
    
    # Normalize to forward slashes
    normalized = path.replace("\\", "/")
    
    # Remove trailing slashes
    if normalized.endswith("/"):
        normalized = normalized.removesuffix("/")
    
    # Find last slash
    last_slash = normalized.rfind("/")
    if last_slash == -1:
        return ""
    
    return normalized[:last_slash]

paths = struct(
    basename = _basename,
    join = _join,
    dirname = _dirname,
)
